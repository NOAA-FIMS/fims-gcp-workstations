# Dockerfile
# This file builds an image containing R, the specified system packages
# and the required R packages, RStudio Server, and code-server.

# Use the same base image specified in devcontainer.json
FROM ghcr.io/rocker-org/devcontainer/r-ver:4.3

# Switch to the root user to install system and R packages
USER root

# Install system dependencies as specified by the 'apt-packages' feature.
# The DEBIAN_FRONTEND env var is used to avoid interactive prompts during the build.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gdb \
    valgrind \
    # Dependencies for RStudio Server
    gdebi-core \
    wget \
    npm \
    libclang-dev \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    # rm -rf /var/lib/apt/lists/*
# Install ps-tree using npm
RUN npm install -g ps-tree

# Add the CRAN repository configuration from 'postCreateCommand' directly into the image.
# This ensures R scripts and package installations can always find the CRAN mirror.
RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> "$(R RHOME)/etc/Rprofile.site"

# Install R packages from the 'r-packages' feature using pak
# For VSCode R Session Watcher (from code-server): jsonlite, rlang
#RUN R -e "pak::pkg_install(c('remotes', 'here', 'r4ss', 'dplyr', 'ggplot2', 'Rcpp', 'RcppEigen', 'snowfall', 'TMB', 'tibble', 'tidyr'))"
#RUN R -e "remotes::install_github(repo = 'cmlegault/ASAPplots')"
#RUN R -e "remotes::install_github(repo = 'NOAA-FIMS/Age_Structured_Stock_Assessment_Model_Comparison')"
#RUN R -e "remotes::install_github(repo = 'NOAA-FIMS/FIMS', ref = '10d5103cecdf2e37b724eb15dbf66dfb146c472b')"
RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"

# Restore the R environment
RUN R -e "renv::restore()"

# Install RStudio Server from the 'rstudio-server' feature
# Check for the latest Ubuntu 22.04 (Jammy) version at https://posit.co/download/rstudio-server/
ENV RSTUDIO_VERSION=2025.05.1-513
RUN wget "https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb" -O rstudio-server.deb && \
    gdebi -n rstudio-server.deb && \
    rm rstudio-server.deb
# Install code-server using its official install script
# Install code-server to enable interactive R development (e.g., using Ctrl+Enter).
# It runs the entire VS Code environment inside the container, bridging the gap
# between the editor and the R session. This serves as an alternative
# when the proprietary "Dev Containers" extension is unavailable.
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Add RStudio bin directory to the PATH
ENV PATH="/usr/lib/rstudio-server/bin:${PATH}"

# Switch back to the default non-root user provided by the base image
USER root