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
import plotly.graph_objects as go

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

EFFICIENCY_QUERY = """
WITH tot AS (
    SELECT ps.player_id,
           SUM(ps.shots)          AS shots,
           SUM(ps.shots_on_goal)  AS sot,
           SUM(ps.goals)          AS goals,
           SUM(ps.minutes_played) AS minutes
    FROM player_stats ps
    GROUP BY ps.player_id
)
SELECT p.name, t.country, t.confederation,
       tot.shots, tot.sot, tot.goals, tot.minutes
FROM tot
JOIN players p ON tot.player_id = p.player_id
JOIN teams   t ON p.team_id     = t.team_id
WHERE tot.shots >= 8            -- 59 players: readable density (>=6 clutters, >=10 too thin)
ORDER BY tot.shots DESC
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

# --- Chart 3: LinkedIn dark finishing-efficiency (folded in from wc26_viz_linkedin.py) ---
# Encodes four variables: player (label), shots (x), goals (y), shots-on-goal (bubble area),
# conversion rate (colour). Exports a 1200x630 PNG (LinkedIn 1.91:1). `shots_on_goal` is the
# FBref SoT column — confirmed against PRAGMA table_info(player_stats).
N_LABELS = 5   # annotate the top-N scorers only (avoid label clutter)

# Dark palette that pops against LinkedIn's white/grey feed
BG, INK, MUTE, GRID = "#0e1117", "#e8eaed", "#9aa0a8", "#262b33"

LINKEDIN_QUERY = """
WITH tot AS (
    SELECT ps.player_id,
           SUM(ps.shots)         AS shots,
           SUM(ps.shots_on_goal) AS sot,
           SUM(ps.goals)         AS goals
    FROM player_stats ps
    GROUP BY ps.player_id
)
SELECT p.name, p.team_id, tot.shots, tot.sot, tot.goals
FROM tot
JOIN players p ON tot.player_id = p.player_id
WHERE tot.goals >= 3 AND tot.shots > 0
ORDER BY tot.goals DESC, tot.shots ASC
"""

# Explicit tag directions for key players (ax, ay), matched by substring on the name.
# ax < 0 = tag to the LEFT of the bubble, ax > 0 = to the RIGHT. Others fall back to auto.
LABEL_DIR = [
    ("Bellingham", (-60, -40)),   # tag points top-left
    ("Mbapp",       (60, -34)),   # tag points top-right
    ("Haaland",     (58, -40)),   # tag points top-right
    ("Messi",      (-58, -40)),   # tag points top-left
]


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


def load_efficiency_data():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        df = pd.read_sql(EFFICIENCY_QUERY, conn)   # query FIRST, conn SECOND
    finally:
        if conn:
            conn.close()
    logging.info(f"finishing_efficiency: loaded {len(df)} players.")
    return df


def pick_efficiency_labels(df):
    """Return up to 4 story-worthy players to annotate:
    - clinical: best goals-per-shot
    - wasteful: most shots among players with <=1 goal
    - volume: most raw shots
    - scorer: most goals
    """
    d = df.copy()
    d["goals_per_shot"] = d["goals"] / d["shots"]

    picks = {}
    picks["clinical"] = d.loc[d["goals_per_shot"].idxmax()]
    wasteful_pool = d[d["goals"] <= 1]
    if not wasteful_pool.empty:
        picks["wasteful"] = wasteful_pool.loc[wasteful_pool["shots"].idxmax()]
    picks["volume"] = d.loc[d["shots"].idxmax()]
    picks["scorer"] = d.loc[d["goals"].idxmax()]

    # Deduplicate — one player can win multiple categories
    seen, unique = set(), []
    for label, row in picks.items():
        if row["name"] not in seen:
            seen.add(row["name"])
            unique.append((label, row))
    return unique


def efficiency_scatter(df):
    """Scatter: shots (x) vs goals (y), bubble = minutes, coloured by confederation.
    A dashed guide line marks the tournament-average conversion rate — points above
    it are clinical finishers, points below are wasteful."""
    conf_order = ["UEFA", "CONMEBOL", "AFC", "CAF", "CONCACAF", "OFC"]
    color_seq  = [CONF_COLORS[c] for c in conf_order if c in df["confederation"].unique()]

    fig = px.scatter(
        df,
        x="shots",
        y="goals",
        size="minutes",
        size_max=28,
        color="confederation",
        category_orders={"confederation": conf_order},
        color_discrete_sequence=color_seq,
        hover_name="name",
        hover_data={
            "country": True,
            "shots": True,
            "sot": True,
            "goals": True,
            "minutes": True,
            "confederation": False,
        },
        labels={
            "shots": "Shots — tournament total",
            "goals": "Goals — tournament total",
        },
        title="Shots vs goals — finishing efficiency (through Round of 16)",
        height=600,
    )

    fig.update_traces(marker=dict(opacity=0.8, line=dict(width=0.5, color="white")))

    # Tournament-average conversion guide line: goals = conv * shots.
    conv  = df["goals"].sum() / df["shots"].sum()
    x_max = df["shots"].max()
    fig.add_shape(
        type="line", x0=0, y0=0, x1=x_max, y1=conv * x_max,
        line=dict(color="#bbbbbb", width=1, dash="dash"), layer="below",
    )
    # Label sits mid-line in the empty lower-left, angled along the slope —
    # keeps it clear of the dense point cloud and the right-edge annotations.
    mid_x = x_max * 0.28
    fig.add_annotation(
        x=mid_x, y=conv * mid_x, xanchor="center", yanchor="bottom",
        text=f"tournament avg — {conv * 100:.0f}% of shots scored",
        showarrow=False, textangle=-8, font=dict(size=10, color="#999"),
    )

    fig.update_layout(
        plot_bgcolor="white",
        paper_bgcolor="white",
        font=dict(family="Arial, sans-serif", size=13, color="#333"),
        title=dict(font=dict(size=18, color="#111"), x=0.03, y=0.97),
        legend=dict(title="", orientation="v", x=1.01, y=0.98, font=dict(size=12)),
        xaxis=dict(title_font=dict(size=13), showgrid=True, gridcolor="#efefef",
                   zeroline=False, dtick=2),
        yaxis=dict(title_font=dict(size=13), showgrid=True, gridcolor="#efefef",
                   zeroline=False, dtick=1),
        margin=dict(l=60, r=180, t=80, b=60),
    )

    # Annotate the story-worthy players (text in ink tokens, not the series colour)
    label_positions = {
        "clinical": (45, -30),
        "wasteful": (0,  35),
        "volume":   (50,  20),
        "scorer":   (-45, -35),
    }
    for label, row in pick_efficiency_labels(df):
        ax, ay = label_positions.get(label, (45, -30))
        fig.add_annotation(
            x=row["shots"], y=row["goals"], text=row["name"],
            showarrow=True, arrowhead=2, arrowcolor="#999", arrowsize=0.8, arrowwidth=1,
            ax=ax, ay=ay, font=dict(size=11, color="#222"),
            bgcolor="rgba(255,255,255,0.85)", bordercolor="#ccc", borderwidth=0.8, borderpad=4,
        )

    return fig


def load_linkedin_data():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        df = pd.read_sql(LINKEDIN_QUERY, conn)   # query FIRST, conn SECOND
    finally:
        if conn:
            conn.close()
    df["conversion"]     = 100.0 * df["goals"] / df["shots"]
    df["shots_per_goal"] = df["shots"] / df["goals"]
    logging.info(f"linkedin_efficiency: loaded {len(df)} players (goals >= 3).")
    return df


def _label_offsets(sub):
    """Leader-line offsets that separate near-identical points (e.g. Bellingham/Haaland).
    Key players get an explicit direction (LABEL_DIR); the rest push outward from the
    horizontal midpoint, alternating above/below by x-rank."""
    x_mid = (sub["shots"].min() + sub["shots"].max()) / 2
    order = sub.sort_values("shots").index.tolist()
    offs = {}
    for i, idx in enumerate(order):
        name = str(sub.loc[idx, "name"])
        override = next((off for key, off in LABEL_DIR if key in name), None)
        if override:
            offs[idx] = override
            continue
        ax = -55 if sub.loc[idx, "shots"] >= x_mid else 55
        ay = -42 if i % 2 == 0 else 46
        offs[idx] = (ax, ay)
    return offs


def finishing_efficiency_linkedin(df):
    """Dark LinkedIn scatter: shots (x) vs goals (y), bubble area = shots-on-goal,
    colour gradient = conversion rate (goals/shot) — the clinical dimension."""
    labels = df.nlargest(N_LABELS, "goals")
    offs   = _label_offsets(labels)

    # bubble area from shots-on-goal
    smax = max(df["sot"].max(), 1)

    fig = go.Figure(go.Scatter(
        x=df["shots"], y=df["goals"], mode="markers",
        marker=dict(
            size=df["sot"], sizemode="area",
            sizeref=2.0 * smax / (56.0 ** 2), sizemin=6,
            color=df["conversion"], colorscale="Plasma",
            cmin=float(df["conversion"].quantile(0.05)),
            cmax=float(df["conversion"].quantile(0.95)),
            showscale=True,
            colorbar=dict(title=dict(text="Conversion %<br>(goals / shot)",
                                     font=dict(size=14, color=INK)),
                          tickfont=dict(size=13, color=INK), thickness=16, len=0.7, x=1.01),
            line=dict(width=1, color=BG), opacity=0.92,
        ),
        customdata=df[["name", "team_id", "sot", "shots_per_goal", "conversion"]].values,
        hovertemplate=("<b>%{customdata[0]}</b> (%{customdata[1]})<br>"
                       "Goals %{y} · Shots %{x} · On target %{customdata[2]}<br>"
                       "%{customdata[3]:.1f} shots/goal · %{customdata[4]:.0f}% conversion<extra></extra>"),
    ))

    for idx, row in labels.iterrows():
        ax, ay = offs[idx]
        fig.add_annotation(
            x=row["shots"], y=row["goals"], ax=ax, ay=ay,
            text=f"<b>{row['name']}</b>", showarrow=True, arrowhead=2,
            arrowcolor=MUTE, arrowsize=0.8, arrowwidth=1.1,
            font=dict(size=16, color=INK), align="center",
        )

    fig.update_layout(
        template="plotly_dark",
        title=dict(
            text=("<b>Volume vs precision — WC26's top scorers</b><br>"
                  f"<span style='font-size:16px;color:{MUTE}'>The Golden Boot leaders were the least "
                  "clinical: Mbappé needed 4.1 shots per goal, Bellingham just 2.7</span>"),
            font=dict(size=29, color=INK), x=0.045, y=0.94),
        paper_bgcolor=BG, plot_bgcolor=BG,
        font=dict(family="Arial, sans-serif", color=INK),
        xaxis=dict(title=dict(text="Shots", font=dict(size=19)),
                   tickfont=dict(size=15), gridcolor=GRID, zeroline=False),
        yaxis=dict(title=dict(text="Goals", font=dict(size=19)),
                   tickfont=dict(size=15), gridcolor=GRID, zeroline=False, dtick=1),
        margin=dict(l=70, r=40, t=115, b=80),
        showlegend=False,
    )
    fig.add_annotation(text="Data: FBref · 2026 World Cup (104 matches)",
                       xref="paper", yref="paper", x=0.045, y=-0.13, showarrow=False,
                       font=dict(size=12, color=MUTE), xanchor="left")
    return fig


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    # Chart 1 — money vs goals (group stage)
    money_df  = load_money_data()
    money_fig = money_vs_goals(money_df)
    money_path = os.path.join(OUT_DIR, "money_vs_goals.html")
    money_fig.write_html(money_path)
    logging.info(f"money_vs_goals: chart written to {money_path}.")

    # Chart 2 — finishing efficiency (group + knockout, 94-match dataset)
    eff_df   = load_efficiency_data()
    eff_fig  = efficiency_scatter(eff_df)
    eff_html = os.path.join(OUT_DIR, "finishing_efficiency.html")
    eff_fig.write_html(eff_html)
    logging.info(f"finishing_efficiency: {len(eff_df)} players -> {eff_html}.")

    # Best-effort static PNG (needs kaleido; the HTML is the guaranteed asset)
    eff_png = os.path.join(OUT_DIR, "finishing_efficiency.png")
    try:
        eff_fig.write_image(eff_png, width=1000, height=600, scale=2)
        logging.info(f"finishing_efficiency: static PNG written to {eff_png}.")
        png_note = eff_png
    except Exception as e:
        logging.warning(f"finishing_efficiency: PNG export skipped ({e}).")
        png_note = "(PNG skipped — kaleido not installed)"

    # Chart 3 — LinkedIn dark finishing-efficiency (volume vs precision, 104-match)
    lin_df   = load_linkedin_data()
    lin_fig  = finishing_efficiency_linkedin(lin_df)
    lin_html = os.path.join(OUT_DIR, "efficiency_linkedin.html")
    lin_fig.write_html(lin_html)
    logging.info(f"linkedin_efficiency: {len(lin_df)} players -> {lin_html}.")

    lin_png = os.path.join(OUT_DIR, "efficiency_linkedin.png")
    try:
        lin_fig.write_image(lin_png, width=1200, height=630, scale=2)   # LinkedIn 1.91:1
        lin_note = lin_png
    except Exception as e:
        logging.warning(f"linkedin_efficiency: PNG export skipped ({e}).")
        lin_note = "(PNG skipped — kaleido not installed)"

    print("Done — charts written:")
    print(f"  {money_path}")
    print(f"  {eff_html}")
    print(f"  {png_note}")
    print(f"  {lin_html}")
    print(f"  {lin_note}")


if __name__ == "__main__":
    main()
