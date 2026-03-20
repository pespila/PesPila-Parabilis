"""Historical Results page with prediction comparison and betting simulation."""

from pathlib import Path

import pandas as pd
import plotly.graph_objects as go
import streamlit as st
from components.league_selector import get_matchdays, league_selector
from utils.cache import get_matches

DB_PATH = Path("data/pespila.db")

MODELS = ["SvS/CvC", "Dixon-Coles", "Elo", "Bradley-Terry"]

st.header("Historical Results")

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="hist_")

if league_id and season_id:
    matchdays = get_matchdays(DB_PATH, league_id, season_id)

    if matchdays:
        selected_md = st.sidebar.selectbox(
            "Matchday",
            matchdays,
            format_func=lambda x: f"Matchday {x}",
        )
        matches = get_matches(str(DB_PATH), league_id, season_id, selected_md)

        if matches.empty:
            st.info("No matches found.")
        else:
            # --- Basic results table ---
            st.subheader(f"Matchday {selected_md}")
            display = matches.rename(columns={
                "match_date": "Date", "home_team": "Home", "away_team": "Away",
                "fthg": "HG", "ftag": "AG", "ftr": "Result",
            })
            st.dataframe(
                display[["Date", "Home", "Away", "HG", "AG", "Result"]],
                use_container_width=True, hide_index=True,
            )

            # --- Prediction comparison ---
            st.markdown("---")
            st.subheader("Prediction vs Actuals")

            col_model, col_stake = st.columns([2, 1])
            with col_model:
                model_name = st.selectbox("Model", MODELS, key="hist_model")
            with col_stake:
                stake = st.number_input("Stake per match ($)", min_value=1.0, value=10.0, step=1.0)

            from pespila.fit_pipeline import FitPipeline
            from pespila.predict import MatchPredictor

            predictor = MatchPredictor(db_path=DB_PATH)
            fitted = predictor.is_fitted(model_name, league_id, season_id)

            if not fitted:
                st.warning(f"Model '{model_name}' not fitted yet.")
                if st.button(f"Fit {model_name} now", type="primary"):
                    with st.spinner(f"Fitting {model_name}..."):
                        fp = FitPipeline(db_path=DB_PATH)
                        if model_name == "SvS/CvC":
                            success = fp.fit_distributions(league_id, season_id)
                        elif model_name == "Dixon-Coles":
                            success = fp.fit_dixon_coles(league_id, season_id)
                        elif model_name == "Elo":
                            success = fp.fit_elo(league_id, season_id)
                        elif model_name == "Bradley-Terry":
                            success = fp.fit_bradley_terry(league_id, season_id)
                        else:
                            success = False
                        if success:
                            st.success(f"{model_name} fitted!")
                            st.rerun()
                        else:
                            st.error("Fitting failed.")
            else:
                # Run predictions for all matches in this matchday
                rows = []
                for _, m in matches.iterrows():
                    try:
                        pred = predictor.predict(
                            model_name, m["home_team"], m["away_team"],
                            league_id, season_id,
                        )
                        pred_result = pred.result
                        actual = m["ftr"]
                        correct = pred_result == actual

                        # Betting P/L
                        odds_map = {"H": m["b365h"], "D": m["b365d"], "A": m["b365a"]}
                        bet_odd = odds_map.get(pred_result)
                        if correct and bet_odd and pd.notna(bet_odd):
                            profit = stake * (float(bet_odd) - 1.0)
                        else:
                            profit = -stake

                        rows.append({
                            "Home": m["home_team"],
                            "Away": m["away_team"],
                            "Score": f"{m['fthg']}-{m['ftag']}",
                            "Actual": actual,
                            "Predicted": pred_result,
                            "P(H)": f"{pred.home_win:.1f}%",
                            "P(D)": f"{pred.draw:.1f}%",
                            "P(A)": f"{pred.away_win:.1f}%",
                            "Correct": correct,
                            "B365 Odd": f"{bet_odd:.2f}" if bet_odd and pd.notna(bet_odd) else "-",
                            "P/L": profit,
                        })
                    except Exception:
                        rows.append({
                            "Home": m["home_team"], "Away": m["away_team"],
                            "Score": f"{m['fthg']}-{m['ftag']}", "Actual": m["ftr"],
                            "Predicted": "ERR", "P(H)": "-", "P(D)": "-", "P(A)": "-",
                            "Correct": False, "B365 Odd": "-", "P/L": 0.0,
                        })

                result_df = pd.DataFrame(rows)

                # Summary stats
                n_correct = result_df["Correct"].sum()
                n_total = len(result_df)
                accuracy = n_correct / n_total * 100 if n_total > 0 else 0
                total_pl = result_df["P/L"].sum()

                col1, col2, col3, col4 = st.columns(4)
                col1.metric("Accuracy", f"{accuracy:.0f}%")
                col2.metric("Correct", f"{n_correct}/{n_total}")
                col3.metric("Total P/L", f"${total_pl:+.2f}")
                col4.metric("ROI", f"{total_pl / (stake * n_total) * 100:+.1f}%" if n_total > 0 else "0%")

                # Styled results table
                display_cols = ["Home", "Away", "Score", "Actual", "Predicted",
                                "P(H)", "P(D)", "P(A)", "B365 Odd", "P/L"]
                styled = result_df[display_cols].style.apply(
                    lambda row: (
                        ["background-color: #1a7a3a; color: #ffffff"] * len(row)
                        if result_df.loc[row.name, "Correct"]
                        else ["background-color: #a82a2a; color: #ffffff"] * len(row)
                    ),
                    axis=1,
                ).format({"P/L": "${:+.2f}"})

                st.dataframe(styled, use_container_width=True, hide_index=True)

                # --- Cumulative P/L chart across the season ---
                st.markdown("---")
                st.subheader("Season Betting Simulation")

                if st.button("Run full season simulation", key="full_season_sim"):
                    with st.spinner("Running predictions for all matchdays..."):
                        all_matches = get_matches(str(DB_PATH), league_id, season_id)
                        cum_pl = []
                        running_total = 0.0
                        md_labels = []
                        md_correct = []
                        md_total_count = []

                        for md in matchdays:
                            md_matches = all_matches[all_matches["matchday"] == md]
                            md_profit = 0.0
                            md_hits = 0
                            md_count = 0

                            for _, m in md_matches.iterrows():
                                try:
                                    pred = predictor.predict(
                                        model_name, m["home_team"], m["away_team"],
                                        league_id, season_id,
                                    )
                                    actual = m["ftr"]
                                    correct = pred.result == actual

                                    odds_map = {"H": m["b365h"], "D": m["b365d"], "A": m["b365a"]}
                                    bet_odd = odds_map.get(pred.result)

                                    if correct and bet_odd and pd.notna(bet_odd):
                                        md_profit += stake * (float(bet_odd) - 1.0)
                                    else:
                                        md_profit -= stake

                                    if correct:
                                        md_hits += 1
                                    md_count += 1
                                except Exception:
                                    md_profit -= stake
                                    md_count += 1

                            running_total += md_profit
                            cum_pl.append(running_total)
                            md_labels.append(md)
                            md_correct.append(md_hits)
                            md_total_count.append(md_count)

                        # Summary
                        total_matches = sum(md_total_count)
                        total_correct = sum(md_correct)
                        season_acc = total_correct / total_matches * 100 if total_matches > 0 else 0

                        c1, c2, c3, c4 = st.columns(4)
                        c1.metric("Season Accuracy", f"{season_acc:.1f}%")
                        c2.metric("Correct", f"{total_correct}/{total_matches}")
                        c3.metric("Final P/L", f"${running_total:+.2f}")
                        c4.metric(
                            "Season ROI",
                            f"{running_total / (stake * total_matches) * 100:+.1f}%"
                            if total_matches > 0 else "0%",
                        )

                        # Cumulative P/L chart
                        fig = go.Figure()
                        fig.add_trace(go.Scatter(
                            x=md_labels, y=cum_pl,
                            mode="lines+markers",
                            name="Cumulative P/L",
                            line=dict(width=2),
                            marker=dict(size=4),
                        ))
                        fig.add_hline(y=0, line_dash="dash", line_color="gray")
                        fig.update_layout(
                            xaxis_title="Matchday",
                            yaxis_title="Cumulative P/L ($)",
                            height=400,
                        )
                        st.plotly_chart(fig, use_container_width=True)

                        # Accuracy per matchday
                        md_acc = [
                            h / t * 100 if t > 0 else 0
                            for h, t in zip(md_correct, md_total_count)
                        ]
                        fig2 = go.Figure()
                        fig2.add_trace(go.Bar(
                            x=md_labels, y=md_acc,
                            name="Accuracy %",
                            marker_color=[
                                "#2ecc71" if a >= 50 else "#e74c3c" for a in md_acc
                            ],
                        ))
                        fig2.update_layout(
                            xaxis_title="Matchday",
                            yaxis_title="Accuracy (%)",
                            height=350,
                        )
                        st.plotly_chart(fig2, use_container_width=True)
    else:
        st.info("No matchday data found. Run compute_all_matchdays() first.")
