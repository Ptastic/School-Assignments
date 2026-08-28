# pages/manufacturer_view.py
import streamlit as st
import pandas as pd
import plotly.express as px

# Set background color for this page (light pink)
st.markdown(
    """
    <style>
    .stApp {
        background-color: #EAEAEA;
    }
    
    </style>
    """,
    unsafe_allow_html=True
)
col0, col1, col2, col3 = st.columns(4) 

with col0:
    st.page_link("home.py", label="🏠 Game Home page")
with col1:
    st.page_link("pages/consoles_view.py", label="📺Consoles Overview")  
with col2:
    st.page_link("pages/global_game_sales.py", label="🎮Global Game Sales")

with col3:
    st.page_link("pages/manufacturer_view.py", label="🔍Manufacturer View")
    
# Access shared data and color schemes from session state
merged_games = st.session_state.merged_games
Consoles_sales = st.session_state.Consoles_sales
manufacturer_colors = st.session_state.manufacturer_colors
st.sidebar.header("Filter by Manufacturer")
manufacturer = st.sidebar.selectbox("Select Manufacturer", ["Sony", "Microsoft", "Nintendo", "Others"], key="select_manufacturer")
filtered_games = merged_games[merged_games["manufacturer"] == manufacturer]
filtered_consoles = Consoles_sales[Consoles_sales["Company"] == manufacturer]


st.header(f"Console Sales for {manufacturer}")
st.write("Total units sold for each console by this manufacturer (in millions).")
fig_consoles = px.bar(filtered_consoles.sort_values("Units sold (million)", ascending=False), 
                      x="Console Name", y="Units sold (million)", color="Company",
                      title="Console Sales (Millions)",
                      color_discrete_map=manufacturer_colors)

fig_consoles.update_layout(
    plot_bgcolor="#EAEAEA",  
    paper_bgcolor="#EAEAEA"  
)

st.plotly_chart(fig_consoles)
st.markdown("---")

st.header(f"Top Selling Games for {manufacturer}")
st.write("The top 10 best-selling games by this manufacturer (in millions).")
top_games = filtered_games.nlargest(10, "Global_Sales")
fig_games = px.bar(top_games, x="Name", y="Global_Sales", title="Top 10 Games (Millions)",
                   color="manufacturer", color_discrete_map=manufacturer_colors)

fig_games.update_layout(
    plot_bgcolor="#EAEAEA", 
    paper_bgcolor="#EAEAEA" 
)

st.plotly_chart(fig_games)

st.header(f"Game Scores for {manufacturer}")
st.write("Scatter plot showing Metascore vs. Global Sales for games by this manufacturer.")
if filtered_games["metascore"].notna().sum() == 0:
    st.write("No score data available for this manufacturer.")
else:
    fig_scores = px.scatter(filtered_games, x="metascore", y="Global_Sales", hover_data=["Name"], 
                        title="Metascore vs. Global Sales (Millions)",  # Uppdaterad titel
                        color="manufacturer", color_discrete_map=manufacturer_colors)
    # Uppdatera bakgrundsfärger för grafen
    fig_scores.update_layout(
        plot_bgcolor="#FFFFFF",  
        paper_bgcolor="#EAEAEA" 
    )
    st.plotly_chart(fig_scores)
st.markdown("---")
st.header(f"Top 15 Games by Average Score for {manufacturer}")
st.write("The top 15 games with the highest average scores (0-100) for this manufacturer.")
top_15_scores = filtered_games[filtered_games["avg_score"].notna()].nlargest(15, "avg_score")
fig_top_scores = px.bar(top_15_scores, x="Name", y="avg_score", title="Top 15 Games (Average Score 0-100)",
                        color="manufacturer", color_discrete_map=manufacturer_colors)

fig_top_scores.update_layout(
    plot_bgcolor="#EAEAEA",  
    paper_bgcolor="#EAEAEA"  
)

st.plotly_chart(fig_top_scores)

st.header(f"Bottom 15 Games by Average Score for {manufacturer}")
st.write("The bottom 15 games with the lowest average scores (0-100) for this manufacturer.")
bottom_15_scores = filtered_games[filtered_games["avg_score"].notna()].nsmallest(15, "avg_score")
fig_bottom_scores = px.bar(bottom_15_scores, x="Name", y="avg_score", title="Bottom 15 Games (Average Score 0-100)",
                           color="manufacturer", color_discrete_map=manufacturer_colors)
# Uppdatera bakgrundsfärger för grafen
fig_bottom_scores.update_layout(
    plot_bgcolor="#EAEAEA",  # Vit bakgrund runt grafen
    paper_bgcolor="#EAEAEA",  # Matchar sidans ljusrosa bakgrund
    xaxis_tickangle=-45 
)
st.plotly_chart(fig_bottom_scores)

st.subheader("Summary")
st.write(f"Key statistics for {manufacturer}.")

summary_data = {
    "Total Games": len(filtered_games),
    "Total Sales": filtered_games["Global_Sales"].sum().round(1),
    "Average Score": filtered_games["avg_score"].mean().round(1) if filtered_games["avg_score"].notna().sum() > 0 else "N/A"
}

summary_df = pd.DataFrame.from_dict(summary_data, orient="index", columns=["Value"])
summary_df["Unit"] = ["each", "millions", "score"]
st.write(summary_df.style.format({"Value": "{:.1f}"}).set_table_attributes('style="width: 20%; margin: auto;"'))
st.markdown("---")
