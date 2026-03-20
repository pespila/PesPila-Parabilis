"""Match Predictions page — on-demand prediction for any matchup."""

from pathlib import Path

import numpy as np
import plotly.graph_objects as go
import streamlit as st
from components.league_selector import league_selector

DB_PATH = Path("data/pespila.db")

st.header("Match Predictions")

MODELS = ["SvS/CvC", "Dixon-Coles", "Elo", "Bradley-Terry"]

league_id, season_id, season_label = league_selector(DB_PATH, key_prefix="pred_")

if league_id and season_id:
    model_name = st.sidebar.selectbox("Model", MODELS)

    # Import here to avoid slow import on page load
    from pespila.fit_pipeline import FitPipeline
    from pespila.predict import MatchPredictor

    predictor = MatchPredictor(db_path=DB_PATH)
    teams = predictor.get_teams(league_id, season_id)

    if not teams:
        st.warning("No teams found for this league/season.")
    else:
        col1, col2 = st.columns(2)
        with col1:
            home_team = st.selectbox("Home Team", teams, key="pred_home")
        with col2:
            away_default = [t for t in teams if t != home_team]
            away_team = st.selectbox("Away Team", away_default, key="pred_away")

        # Check if model is fitted
        fitted = predictor.is_fitted(model_name, league_id, season_id)

        if not fitted:
            st.warning(f"Model '{model_name}' has not been fitted for this league/season.")
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
                        st.success(f"{model_name} fitted successfully!")
                        st.rerun()
                    else:
                        st.error(f"Failed to fit {model_name}.")
        else:
            if st.button("Predict", type="primary"):
                try:
                    pred = predictor.predict(
                        model_name, home_team, away_team, league_id, season_id
                    )

                    # Result header
                    result_map = {"H": "Home Win", "D": "Draw", "A": "Away Win"}
                    st.subheader(f"Prediction: {result_map[pred.result]}")
                    st.markdown(f"**{home_team} {pred.home_goals} - {pred.away_goals} {away_team}**")

                    # Probability bars
                    fig = go.Figure()
                    fig.add_trace(go.Bar(
                        y=["Prediction"],
                        x=[pred.home_win],
                        name=f"Home ({pred.home_win:.1f}%)",
                        orientation="h",
                        marker_color="#2ecc71",
                        text=f"{pred.home_win:.1f}%",
                        textposition="inside",
                    ))
                    fig.add_trace(go.Bar(
                        y=["Prediction"],
                        x=[pred.draw],
                        name=f"Draw ({pred.draw:.1f}%)",
                        orientation="h",
                        marker_color="#95a5a6",
                        text=f"{pred.draw:.1f}%",
                        textposition="inside",
                    ))
                    fig.add_trace(go.Bar(
                        y=["Prediction"],
                        x=[pred.away_win],
                        name=f"Away ({pred.away_win:.1f}%)",
                        orientation="h",
                        marker_color="#e74c3c",
                        text=f"{pred.away_win:.1f}%",
                        textposition="inside",
                    ))
                    fig.update_layout(
                        barmode="stack",
                        height=120,
                        margin=dict(l=0, r=0, t=0, b=0),
                        showlegend=True,
                        legend=dict(orientation="h", yanchor="bottom", y=-0.5),
                        xaxis=dict(showticklabels=False, range=[0, 100]),
                        yaxis=dict(showticklabels=False),
                    )
                    st.plotly_chart(fig, use_container_width=True)

                    # Odds
                    col1, col2, col3 = st.columns(3)
                    col1.metric("Home Odd", f"{pred.home_odd:.2f}")
                    col2.metric("Draw Odd", f"{pred.draw_odd:.2f}")
                    col3.metric("Away Odd", f"{pred.away_odd:.2f}")

                    # 6x6 probability heatmap
                    if pred.matrix is not None:
                        st.subheader("Scoreline Probability Matrix")
                        fig_heat = go.Figure(data=go.Heatmap(
                            z=pred.matrix * 100,
                            x=[str(i) for i in range(pred.matrix.shape[1])],
                            y=[str(i) for i in range(pred.matrix.shape[0])],
                            colorscale="YlOrRd",
                            text=np.round(pred.matrix * 100, 1).astype(str),
                            texttemplate="%{text}%",
                            hovertemplate="Home %{y} - Away %{x}: %{z:.1f}%<extra></extra>",
                        ))
                        fig_heat.update_layout(
                            xaxis_title="Away Goals",
                            yaxis_title="Home Goals",
                            height=400,
                            yaxis=dict(autorange="reversed"),
                        )
                        st.plotly_chart(fig_heat, use_container_width=True)

                except Exception as e:
                    st.error(f"Prediction failed: {e}")
