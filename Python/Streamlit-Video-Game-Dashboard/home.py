# app.py
#/c/Users/Palle/AppData/Local/Packages/PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0/LocalCache/local-packages/Python313/Scripts/streamlit run home.py
# app.py
import streamlit as st
import pandas as pd
import plotly.express as px

# Load datasets
Game_sales = pd.read_csv("Resources/video games sales.csv")
Games_score = pd.read_csv("Resources/games-score.csv")
Consoles_sales = pd.read_csv("Resources/best-selling game consoles.csv")

st.markdown(
    """
    <style>
    .stApp {
        background-color: #EEF7FA;
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

# Title and description
st.title("Video Game Sales Dashboard")
st.write("Explore video game sales and scores across different consoles and manufacturers.")

# Normalize platform names
platform_normalization = {
    "PS": "PlayStation", "PS2": "PlayStation 2", "PS3": "PlayStation 3", "PS4": "PlayStation 4","PS5": "Playstation 5",
    "XB": "Xbox", "X360": "Xbox 360", "XOne": "Xbox One",
    "NES": "NES", "SNES": "SNES", "Wii": "Wii", "Switch": "Nintendo Switch",
    "DC": "Dreamcast", "Wii U": "Wii U", "WiiU": "Wii U","NES/Famicom":"NESF",
    "GC": "GameCube", "3DS": "Nintendo 3DS","SNES/Super Famicom":"SNES",
    "GB": "Game Boy", "GBA": "Game Boy Advance", "DS": "Nintendo DS", "N64": "Nintendo 64",
    "PSP": "PlayStation Portable", "GBC": "Game Boy Color", "DSI": "Nintendo DSi",
    "GEN": "Sega Genesis", "SAT": "Sega Saturn", "S32X": "Sega 32X", "SCD": "Sega CD",
    "PC": "PC",
    "PSV": "PlayStation Vita"
}
Game_sales["Platform_normalized"] = Game_sales["Platform"].map(platform_normalization).fillna(Game_sales["Platform"])
Games_score["platform_normalized"] = Games_score["platform"].map(platform_normalization).fillna(Games_score["platform"])

# Normalize manufacturer names
manufacturer_mapping = {
    "PlayStation": "Sony", "PlayStation 2": "Sony", "PlayStation 3": "Sony", "PlayStation 4": "Sony","PS5": "Sony","PlayStation 5": "Sony",
    "PlayStation Portable": "Sony", "PlayStation Vita": "Sony","NES/Famicom": "Nintendo", "Super NES Classic Edition":"Nintendo", 
    "Xbox": "Microsoft", "Xbox 360": "Microsoft", "Xbox One": "Microsoft", "NES Classic Edition":"Nintendo",
    "NES": "Nintendo", "SNES": "Nintendo", "Wii": "Nintendo", "Nintendo Switch": "Nintendo",
    "Dreamcast": "Sega", "Wii U": "Nintendo", "GameCube": "Nintendo", "Nintendo 3DS": "Nintendo",
    "Famicom Disk System":"Nintendo","SNES/Super Famicom": "Nintendo","Xbox Series X/S": "Microsoft",
    "Game Boy": "Nintendo", "Game Boy Advance": "Nintendo", "Nintendo DS": "Nintendo", "Nintendo 64": "Nintendo",
    "Game Boy Color": "Nintendo", "Nintendo DSi": "Nintendo","NESF": "Nintendo",
    "Sega Genesis": "Sega", "Sega Saturn": "Sega", "Sega 32X": "Sega", "Sega CD": "Sega",
    "PC": "Others", "Game & Watch": "Nintendo","Sega Game Gear": "Sega", "Sega Pico": "Sega"
}
#Merging data set
Game_sales["manufacturer"] = Game_sales["Platform_normalized"].map(manufacturer_mapping).fillna("Others")
Consoles_sales["Company"] = Consoles_sales["Console Name"].map(manufacturer_mapping).fillna("Others")


# Multiplicera user_score med 10 och räkna ut avg_score
merged_games = pd.merge(Game_sales, Games_score, left_on=["Name", "Platform_normalized"], 
                        right_on=["title", "platform_normalized"], how="left")
merged_games = merged_games.drop_duplicates(subset=["Name", "Platform"])
merged_games["user_score"] = pd.to_numeric(merged_games["user_score"], errors="coerce")
merged_games["user_score"] = merged_games["user_score"] * 10
merged_games["avg_score"] = merged_games[["metascore", "user_score"]].mean(axis=1)

# Define color schemes
manufacturer_colors = {
    "Sony": "#2E89BA",
    "Microsoft": "#58A15B",
    "Nintendo": "#D9603B",
    "Sega": "#FF9800",
    "Others": "#887269"
}
choropleth_color_scale = "Burg"
summary = merged_games.groupby("Platform_normalized").agg({
    "Name": "count",  # Räknar antal spel
    "Global_Sales": "sum"  # Summerar global försäljning
}).rename(columns={"Name": "Number of games", "Global_Sales": "Game Sales (Millions)"})

summary["Game Sales (Millions)"] = summary["Game Sales (Millions)"].round(1)  # Runda av till en decimal
summary.index.name = "Plattform"  # Ändra visningsnamnet för index


# Store data and color schemes in session state
if "merged_games" not in st.session_state:
    st.session_state.merged_games = merged_games
if "Consoles_sales" not in st.session_state:
    st.session_state.Consoles_sales = Consoles_sales
if "manufacturer_colors" not in st.session_state:
    st.session_state.manufacturer_colors = manufacturer_colors
if "choropleth_color_scale" not in st.session_state:
    st.session_state.choropleth_color_scale = choropleth_color_scale

# Add two smaller columns with text and one larger column with a line chart
# merged_games.rename(columns={"avg_score": "Avg Score"}, inplace=True)

col1, col3 = st.columns([1, 3])

# First smaller column with text
with col1:
    st.markdown(
        """
        </br>
        <p style='padding: 20px; text-align: center; margin-bottom: 20px;'>
        <p style='font-size: 20px;'>
        </br>
        </br>
        </br>
        Game Sales Trends by Manufacturer!
        </p>
        <p style='font-size: 18px; margin-top: 20px;'>
        Here you can explore game sales trends across different manufacturers over time.
        </div>
        """,
        unsafe_allow_html=True
    )
# Larger column with a line chart
with col3:
    st.subheader("Game Sales Trends by manufacturer (Millions)")
    # Group data by Year and manufacturer to get total sales per year for each manufacturer
    sales_by_year_manufacturer = merged_games.groupby(["Year", "manufacturer"])["Global_Sales"].sum().reset_index()
    # Create a line chart with Plotly Express
    fig = px.line(sales_by_year_manufacturer, x="Year", y="Global_Sales", color="manufacturer",
                  title="",
                  labels={"Global_Sales": "Global Sales (Millions)", "Year": "Year"},
                  color_discrete_map=manufacturer_colors)
    # Update layout for consistent styling
    fig.update_layout(
        plot_bgcolor="#FFFFFF",  # White background inside the chart
        paper_bgcolor="#EEF7FA",  # Light blue background to match the default page
        showlegend=True,
        margin=dict(l=40, r=40, t=40, b=40)
    )
    st.plotly_chart(fig, use_container_width=True)

st.markdown("---")
col2, col1 = st.columns([3, 1])
with col1:
    st.markdown(
        """
        </br>
        <p style='padding: 20px; text-align: center; margin-bottom: 20px;'>
        <p style='font-size: 20px;'>
        </br>
        </br>
        </br>
        Game Sales Trends by console!
        </div>
        <p style='font-size: 18px; margin-top: 20px;'>
        Here you can explore game sales trends across different Consoles over time.
        """,
        unsafe_allow_html=True
    )
# Larger column with a line chart
with col2:
    st.subheader("Game Sales Trends by console (Millions)")
    # Group data by Year and manufacturer to get total sales per year for each manufacturer
    sales_by_year_manufacturer = merged_games.groupby(["Year", "Platform_normalized"])["Global_Sales"].sum().reset_index()
    # Create a line chart with Plotly Express
    fig = px.line(sales_by_year_manufacturer, x="Year", y="Global_Sales", color="Platform_normalized",
                  title="",
                  labels={"Global_Sales": "Global Sales (Millions)", "Year": "Year"},
                  color_discrete_map=manufacturer_colors)
    # Update layout for consistent styling
    fig.update_layout(
        plot_bgcolor="#FFFFFF",  # White background inside the chart
        paper_bgcolor="#EEF7FA",  # Light blue background to match the default page
        showlegend=True,
        margin=dict(l=40, r=40, t=40, b=40)
    )
    st.plotly_chart(fig, use_container_width=True)

st.markdown("---")
# Second larger column with a scatter plot of top 30 games per manufacturer

st.subheader("Top 30 Games per Manufacturer: Metascore vs Global Sales")
st.write("Sales by score, and coloured by manufacturer")
# Filter games with non-null scores and sales, then select top 30 per manufacturer based on avg_score
games_with_scores_and_sales = merged_games[merged_games["avg_score"].notna() & merged_games["Global_Sales"].notna()]
top_30_per_manufacturer = (games_with_scores_and_sales.groupby("manufacturer")
                            .apply(lambda x: x.nlargest(30, "avg_score"))
                            .reset_index(drop=True))
    
if top_30_per_manufacturer.empty:
    st.write("No score or sales data available for any manufacturer.")
else:
        # Create scatter plot
    fig_scores = px.scatter(top_30_per_manufacturer, x="metascore", y="Global_Sales", 
                            hover_data=["Name"], 
                            title="",
                            color="manufacturer", 
                            color_discrete_map=manufacturer_colors,
                            labels={"metascore": "Metascore: ", "Global_Sales": "Sales(millions)"})
        # Update layout for consistent styling
    fig_scores.update_layout(
        plot_bgcolor="#FFFFFF",
         paper_bgcolor="#EEF7FA",
        margin=dict(l=40, r=40, t=40, b=40)
    )
    st.plotly_chart(fig_scores, use_container_width=True)
    st.markdown("---")
st.subheader("Total Console Sales by Company")
st.write("Total units sold for each console, colored by manufacturer.")

# Använd hela datasetet utan filtrering
fig_console_sales = px.bar(
    Consoles_sales, 
    x="Console Name", 
    y="Units sold (million)",
    color="Company", 
    color_discrete_map=manufacturer_colors,
    labels={"Units sold (million)": "Units Sold (Millions)", "Console Name": "Console"},
    title=""
)

# Anpassa layout
fig_console_sales.update_layout(
    plot_bgcolor="#FFFFFF",
    paper_bgcolor="#EEF7FA",
    margin=dict(l=40, r=40, t=40, b=40),
    xaxis_tickangle=-45
)

st.plotly_chart(fig_console_sales, use_container_width=True)
#st.plotly_chart(fig_console_sales, use_container_width=True)

st.markdown("---")
if st.button("Send balloons!"):
    st.balloons()


