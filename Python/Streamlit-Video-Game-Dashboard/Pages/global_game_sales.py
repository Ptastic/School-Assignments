# pages/global_game_sales.py
import streamlit as st
import pandas as pd
import plotly.express as px

# Set background color for this page (light blue) and add border to Plotly charts
st.markdown(
    """
    <style>
    .stApp {
        background-color: #E6F0FA;
    }
    </style>
    """,
    unsafe_allow_html=True
)
merged_games = st.session_state.merged_games
choropleth_color_scale = st.session_state.choropleth_color_scale

col0, col1, col2, col3 = st.columns(4) 
with col0:
    st.page_link("home.py", label="🏠 Game Home page")
with col1:
    st.page_link("pages/consoles_view.py", label="📺Consoles Overview")  
with col2:
    st.page_link("pages/global_game_sales.py", label="🎮Global Game Sales")
with col3:
    st.page_link("pages/manufacturer_view.py", label="🔍Manufacturer View")


st.header("Global Game Sales")
st.subheader("Search for a Game")

search_term = st.text_input("Enter game name", "")
if search_term:
    search_results = merged_games[merged_games["Name"].str.contains(search_term, case=False, na=False)]
    if len(search_results) > 0:
        st.dataframe(search_results[["Name", "Platform", "manufacturer", "Global_Sales", "avg_score"]])
        st.subheader("Select a Game for Regional Sales")
        selected_game = st.selectbox("Select a Game", ["All Games"] + search_results["Name"].tolist(), key="select_game_search")
    else:
        st.write("No games found.")
        selected_game = "All Games"
else:
    st.subheader("Top 100 Games by Global Sales")
    top_100_games = merged_games.nlargest(100, "Global_Sales")
        # Rename columns for display
    display_df = top_100_games[["Name", "Platform", "manufacturer", "Global_Sales", "avg_score"]].rename(
            columns={"manufacturer": "Manufacturer","Global_Sales": "Sales", "avg_score": "Score"}
    )
    st.dataframe(display_df)
    st.subheader("Select a Game for Regional Sales")
    selected_game = st.selectbox("Select a Game", ["All Games"] + top_100_games["Name"].tolist(), key="select_game_top100")

st.subheader("Regional Sales")
if selected_game and selected_game != "All Games":
    game_data = merged_games[merged_games["Name"] == selected_game]
    regional_sales = {
        "Region": ["NA", "EU", "JP"],
        "Sales": [
            max(game_data["NA_Sales"].sum(), 0.01),
            max(game_data["EU_Sales"].sum(), 0.01),
            max(game_data["JP_Sales"].sum(), 0.01)
        ]
    }
else:
    regional_sales = {
        "Region": ["NA", "EU", "JP"],
        "Sales": [
            max(merged_games["NA_Sales"].sum(), 0.01),
            max(merged_games["EU_Sales"].sum(), 0.01),
            max(merged_games["JP_Sales"].sum(), 0.01)
        ]
    }

regional_sales_df = pd.DataFrame(regional_sales)

region_to_countries = {
    "NA": ["USA", "CAN", "MEX"],
    "EU": ["DEU", "FRA", "ITA", "ESP", "SWE", "DNK", "FIN", "POL", "BEL", "GRC", "ROU", "IRL", "EST", "LTU", 
            "NLD", "CHE", "AUT", "HUN", "SVK", "SVN", "CZE", "HRV", "PRT", "LUX", "MLT", "CYP", "LVA", "BGR",
            "BLR","UKR","ISL","GBR","NOR","ALB","MKD","SRB","BIH","MNE","MLD","MDA"],
    "JP": ["JPN"]
}
choropleth_data = []
for _, row in regional_sales_df.iterrows():
    region = row["Region"]
    sales = row["Sales"]
    for country in region_to_countries[region]:
        choropleth_data.append({"Country": country, "Sales": sales, "Region": region})
choropleth_df = pd.DataFrame(choropleth_data)

title = f"Regional Sales for {selected_game} (Millions)" if selected_game and selected_game != "All Games" else "Regional Sales (All Games, Millions)"
if len(choropleth_df) > 0:
    fig_choropleth = px.choropleth(choropleth_df, locations="Country", locationmode="ISO-3",
                                   color="Sales", hover_name="Country", hover_data=["Region"],
                                   title=title,
                                   color_continuous_scale=choropleth_color_scale)
    # Uppdatera bakgrundsfärger för grafen
    fig_choropleth.update_layout(
        plot_bgcolor="#FFFFFF",  # Vit bakgrund inne i grafen
        paper_bgcolor="#E6F0FA"  # Matchar sidans ljusblå bakgrund
    )
    st.plotly_chart(fig_choropleth)
else:
    st.write("No sales data available for this selection.")