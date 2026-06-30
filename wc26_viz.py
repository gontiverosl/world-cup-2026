"""
wc26_viz.py — Plotly visualizations for WC26.

Layer 4 of the pipeline: worldcup26.db → pandas → Plotly → results/*.html

Usage:
    python3 wc26_viz.py

Charts exported to results/. Open any .html file in a browser.
Install if needed: pip install plotly --break-system-packages
"""
import os
import math
import sqlite3
import logging
import pandas as pd
import plotly.express as px

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH  = os.path.join(BASE_DIR, "worldcup26.db")
OUT_DIR  = os.path.join(BASE_DIR, "results")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

MONEY_QUERY = """
WITH home_goals AS (
    SELECT team_home AS team_id, SUM(goals_home) AS goals
    FROM matches
    WHERE goals_home IS NOT NULL
      AND stage = 'group'
    GROUP BY team_home
),
away_goals AS (
    SELECT team_away AS team_id, SUM(goals_away) AS goals
    FROM matches
    WHERE goals_away IS NOT NULL
      AND stage = 'group'
    GROUP BY team_away
),
totals AS (
    SELECT team_id, SUM(goals) AS group_goals
    FROM (SELECT * FROM home_goals UNION ALL SELECT * FROM away_goals) AS combined
    GROUP BY team_id
)
SELECT
    t.country,
    t.confederation,
    CAST(t.market_value_m AS REAL) AS market_value_m,
    tot.group_goals
FROM teams t
JOIN totals tot ON t.team_id = tot.team_id
WHERE t.market_value_m IS NOT NULL
  AND t.market_value_m > 0
ORDER BY t.market_value_m DESC
"""

# One distinct color per confederation — readable on white
CONF_COLORS = {
    "UEFA":     "#1f77b4",
    "CONMEBOL": "#e05c2a",
    "AFC":      "#2ca02c",
    "CAF":      "#9467bd",
    "CONCACAF": "#d62728",
    "OFC":      "#bcbd22",
}


def load_money_data():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        df = pd.read_sql(MONEY_QUERY, conn)
    finally:
        if conn:
            conn.close()
    logging.info(f"money_vs_goals: loaded {len(df)} teams.")
    return df


def pick_labels(df):
    """
    Return the 5 most story-worthy teams to annotate.
    - Biggest overperformer: highest goals-per-100M ratio
    - Biggest underperformer: lowest goals-per-100M among top-value squads
    - Richest squad
    - Highest scorer
    - Lowest value squad
    """
    df = df[df["market_value_m"] > 0].copy()
    df["goals_per_100m"] = df["group_goals"] / (df["market_value_m"] / 100)

    picks = {}
    picks["top_scorer"]       = df.loc[df["group_goals"].idxmax()]
    picks["richest"]          = df.loc[df["market_value_m"].idxmax()]
    picks["cheapest"]         = df.loc[df["market_value_m"].idxmin()]
    picks["overperformer"]    = df.loc[df["goals_per_100m"].idxmax()]
    # Underperformer: worst ratio among top-10 by squad value
    top10 = df.nlargest(10, "market_value_m")
    picks["underperformer"]   = top10.loc[top10["goals_per_100m"].idxmin()]

    # Deduplicate (same team can win multiple categories)
    seen = set()
    unique = []
    for label, row in picks.items():
        if row["country"] not in seen:
            seen.add(row["country"])
            unique.append((label, row))
    return unique


def money_vs_goals(df):
    """Scatter: squad market value (x, log) vs group-stage goals (y), coloured by confederation."""

    # Sort confederation order for a consistent legend
    conf_order = ["UEFA", "CONMEBOL", "AFC", "CAF", "CONCACAF", "OFC"]
    color_seq  = [CONF_COLORS[c] for c in conf_order if c in df["confederation"].unique()]

    fig = px.scatter(
        df,
        x="market_value_m",
        y="group_goals",
        color="confederation",
        category_orders={"confederation": conf_order},
        color_discrete_sequence=color_seq,
        log_x=True,                       # spreads the left cluster
        hover_name="country",
        hover_data={
            "market_value_m": ":.0f",
            "group_goals": True,
            "confederation": False,
        },
        labels={
            "market_value_m": "Squad value (€M, Transfermarkt) — log scale",
            "group_goals": "Goals scored — group stage",
        },
        title="Did money buy goals? — WC26 group stage",
        height=600,
    )

    fig.update_traces(marker=dict(size=12, opacity=0.88, line=dict(width=0.5, color="white")))

    fig.update_layout(
        plot_bgcolor="white",
        paper_bgcolor="white",
        font=dict(family="Arial, sans-serif", size=13, color="#333"),
        title=dict(font=dict(size=18, color="#111"), x=0.03, y=0.97),
        legend=dict(title="", orientation="v", x=1.01, y=0.98, font=dict(size=12)),
        xaxis=dict(
            title_font=dict(size=13),
            showgrid=True,
            gridcolor="#efefef",
            zeroline=False,
            # no tickformat on log scale — Plotly handles it correctly by default
        ),
        yaxis=dict(
            title_font=dict(size=13),
            showgrid=True,
            gridcolor="#efefef",
            zeroline=False,
            dtick=1,
        ),
        margin=dict(l=60, r=180, t=80, b=60),
    )

    # Annotate the 5 story-worthy teams
    label_positions = {
        "top_scorer":    (50, -35),
        "richest":       (-80, -35),
        "cheapest":      (50, -35),
        "overperformer": (55,  30),
        "underperformer":(-80, 30),
    }

    for label, row in pick_labels(df):
        ax, ay = label_positions.get(label, (50, -30))
        fig.add_annotation(
            x=math.log10(row["market_value_m"]),   # log10 required on log-x axis
            y=row["group_goals"],
            text=row["country"],
            showarrow=True,
            arrowhead=2,
            arrowcolor="#999",
            arrowsize=0.8,
            arrowwidth=1,
            ax=ax,
            ay=ay,
            font=dict(size=11, color="#222"),
            bgcolor="rgba(255,255,255,0.85)",
            bordercolor="#ccc",
            borderwidth=0.8,
            borderpad=4,
        )

    return fig


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    df = load_money_data()
    fig = money_vs_goals(df)

    out_path = os.path.join(OUT_DIR, "money_vs_goals.html")
    fig.write_html(out_path)
    logging.info(f"money_vs_goals: chart written to {out_path}.")
    print(f"Done — open in browser: {out_path}")


if __name__ == "__main__":
    main()
