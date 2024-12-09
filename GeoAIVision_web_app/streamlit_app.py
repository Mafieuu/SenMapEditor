import streamlit as st 



# --- PAGE SETUP ---
models_page = st.Page(
    "views/models.py",
    title="Images segmentation",
    icon=":material/house:",
    default=True,
)
project_1_page = st.Page(
    "views/configure_mobile_app.py",
    title="Configure mobile application",
    icon=":material/install_mobile:",
)
project_2_page = st.Page(
    "views/supervisor.py",
    title="Suivre les modifications",
    icon=":material/folder_managed:",
)


# --- NAVIGATION SETUP [WITHOUT SECTIONS] ---
#pg = st.navigation(pages=[models_page, project_1_page, project_2_page])

# --- NAVIGATION SETUP [WITH SECTIONS]---
pg = st.navigation(
    {
        "modelisation": [models_page],
        "Suivi de terrain": [project_1_page, project_2_page],
    }
)


# --- SHARED ON ALL PAGES ---
st.logo("assets/logo.png")
st.sidebar.markdown("Powered by GeoAIVision")


# --- RUN NAVIGATION ---
pg.run() 