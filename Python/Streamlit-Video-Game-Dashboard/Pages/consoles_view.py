import streamlit as st
import pandas as pd
import plotly.express as px

# Set background color to #F4F2F9 as requested
st.markdown(
    """
    <style>
    .stApp {
        background-color: #F4F2F9;
    }
    </style>
    """,
    unsafe_allow_html=True
)
console_info = {
    "GG": "Sega Game Gear (GG) is a portable gaming console from Sega, released in 1990, which competed with Nintendo's Game Boy.",
    "3DO": "3DO Interactive Multiplayer is an early multimedia console released in 1993, known for its CD-based games.",
    "Nes": "Nintendo Entertainment System (NES) is a classic gaming console that revolutionized the gaming industry when it was released in 1983.",
    "NG": "Neo Geo is a gaming console and arcade machine from SNK, known for its high-quality games and graphics.",
    "PCFX": "PC-FX is a gaming console from NEC, released in 1994, which focused on CD-based games and multimedia.",
    "2600": "Atari 2600 is one of the first successful home consoles, released in 1977, known for its cartridge-based games.",
    "TG16": "TurboGrafx-16 is a gaming console from NEC, released in 1987, which competed with the Sega Genesis and Super Nintendo.",
    "WS": "WonderSwan is a portable gaming console from Bandai, released in 1999, known for its colorful games and long battery life."
}

col0, col1, col2, col3 = st.columns(4)
with col0:
    st.page_link("home.py", label="🏠 Game Home page")
with col1:
    st.page_link("pages/consoles_view.py", label="📺 Consoles Overview")
with col2:
    st.page_link("pages/global_game_sales.py", label="🎮 Global Game Sales")
with col3:
    st.page_link("pages/manufacturer_view.py", label="🔍Manufacturer View")

# Title and description
st.title("Consoles Overview")
st.write("Explore sales and scores for different gaming consoles.")

# Access shared data and color schemes from session state
merged_games = st.session_state.get("merged_games")
Consoles_sales = st.session_state.get("Consoles_sales")
manufacturer_colors = st.session_state.get("manufacturer_colors")

# Check if data is available
if merged_games is None or Consoles_sales is None or manufacturer_colors is None:
    st.error("Required data not found. Please load the data on the Game Home page first.")
else:
    # Sidebar filters
    st.sidebar.header("Filters")
    genres = ["All Genres"] + sorted(merged_games["Genre"].unique().tolist())
    selected_genre = st.sidebar.selectbox("Select Genre", genres, key="select_genre")
    min_year, max_year = int(merged_games["Year"].min()), int(merged_games["Year"].max())
    year_range = st.sidebar.slider("Select Year Range", min_year, max_year, (min_year, max_year))

    # Apply filters to merged_games
    filtered_games_all = merged_games.copy()
    if selected_genre != "All Genres":
        filtered_games_all = filtered_games_all[filtered_games_all["Genre"] == selected_genre]
    filtered_games_all = filtered_games_all[
        (filtered_games_all["Year"] >= year_range[0]) & (filtered_games_all["Year"] <= year_range[1])
    ]

    # Console filter
    st.subheader("Filter by Console")
    consoles = ["All Consoles"] + sorted(Consoles_sales["Console Name"].unique().tolist())
    selected_console = st.selectbox("Console", consoles, key="select_console")
    if selected_console != "All Consoles":
        filtered_games_all = filtered_games_all[filtered_games_all["Platform_normalized"] == selected_console]

    # Section 1: Treemap of top 20 games by sales
    st.subheader("Top 20 Games by Sales (All Consoles)")
    st.write("View the top 20 games by global sales, grouped by manufacturer.(Millions)")
    top_games_all = filtered_games_all.nlargest(20, "Global_Sales")
    if len(top_games_all) > 0:
        fig_top_games_all = px.treemap(top_games_all, 
                                       path=["manufacturer", "Name"], 
                                       values="Global_Sales",
                                       title="",
                                       color="manufacturer", 
                                       color_discrete_map=manufacturer_colors)
        fig_top_games_all.update_layout(
            plot_bgcolor="#FFFFFF",
            paper_bgcolor="#F4F2F9",
            margin=dict(l=40, r=40, t=40, b=40)
        )
        st.plotly_chart(fig_top_games_all, use_container_width=True, height=600)
    else:
        st.write("No games available for this selection.")
    st.markdown("<br>", unsafe_allow_html=True)

    st.subheader("Score Distribution")
    st.write("Distribution of average scores, grouped by manufacturer or console. Also, try filtering by genre and year.")   
    if filtered_games_all["avg_score"].notna().sum() > 0:
            # Create the box plot (grouping will be set after the chart)
        group_by = st.session_state.get("score_group_by", "Manufacturer")  # Default to Manufacturer
        if group_by == "Manufacturer":
            group_col = "manufacturer"
        else:
            group_col = "Platform_normalized"
            
        fig_scores_all = px.box(filtered_games_all[filtered_games_all["avg_score"].notna()], 
                                x=group_col, 
                                y="avg_score",
                                title="",
                                color=group_col,
                            color_discrete_map=manufacturer_colors if group_col == "manufacturer" else None)
        fig_scores_all.update_layout(
            plot_bgcolor="#FFFFFF",
            paper_bgcolor="#F4F2F9",
            margin=dict(l=40, r=40, t=40, b=40),
            xaxis_tickangle=-45
        )
        st.plotly_chart(fig_scores_all, use_container_width=True)
            
            # Place the "Group by" radio button below the chart
        group_by = st.radio("Group by:", ["Manufacturer", "Console"], key="score_group_by")
    else:
        st.write("No score data available for this selection.")
st.markdown("---")
col1, col2 = st.columns([1, 3])

with col1:
    st.markdown(
            """
            </br>
            </div> style='padding: 20px; text-align: center; margin-bottom: 20px;'>
            <p style='font-size: 20px;'>
            </br>
            </br>
            </br>
            Game Sales Trends by Genre!
            </p>
            <p style='font-size: 18px; margin-top: 20px;'>
            Explore how game genres have performed globally over time.
            </div>
            """,
            unsafe_allow_html=True
    )
    
with col2:
    st.subheader("Game Sales Trends by Genre (Millions)")
    genre_sales = merged_games.dropna(subset=["Genre", "Year"])
    genre_sales_grouped = genre_sales.groupby(["Year", "Genre"])["Global_Sales"].sum().reset_index()

    fig_genre = px.line(
         genre_sales_grouped, 
        x="Year", y="Global_Sales", color="Genre",
        labels={"Global_Sales": "Global Sales (Millions)", "Year": "Year"},
        title=""
    )
    fig_genre.update_layout(
        plot_bgcolor="#FFFFFF",
        paper_bgcolor="#F4F2F9",
        showlegend=True,
        margin=dict(l=40, r=40, t=40, b=40)
        )
    st.plotly_chart(fig_genre, use_container_width=True)
    
summary = merged_games.groupby("Platform_normalized").agg({
    "Name": "count",  # Räknar antal spel
    "Global_Sales": "sum"  # Summerar global försäljning
}).rename(columns={"Name": "Number of games", "Global_Sales": "Game Sales (Millions)"})

summary["Game Sales (Millions)"] = summary["Game Sales (Millions)"].round(1)  # Runda av till en decimal
summary.index.name = "Plattform"  # Ändra visningsnamnet för index
summary = summary.reset_index()
st.write(summary.style.format({"Game Sales (Millions)": "{:.1f}"}).set_table_attributes('style="width: 100%; margin: auto;"'))
with st.expander("Learn more about the consoles"):
    for platform, info in console_info.items():
        st.write(f"**{platform}**: {info}")