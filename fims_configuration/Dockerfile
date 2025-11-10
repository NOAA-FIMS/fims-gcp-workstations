# Dockerfile
# This file builds an image containing R, the specified system packages
# and the required R packages.

# Use the Posit image
FROM us-central1-docker.pkg.dev/posit-images/cloud-workstations/workbench:latest

# Switch to the root user to install system and R packages
USER root

# Install system dependencies (for {languageserver}) as specified by the 'apt-packages' feature.
# The DEBIAN_FRONTEND env var is used to avoid interactive prompts during the build.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    r-base && \
    rm -rf /var/lib/apt/lists/*

# Install R packages 
# To be added in the future: 
# - NOAA-FIMS/FIMSdiags (currently cannot be installed because lazy loading failed)
# - NOAA-FIMS/fishprior (take > 40 mins to install the package)

RUN R -e "install.packages('pak', repos = 'https://cloud.r-project.org')"
RUN R -e "pak::pkg_install(c( \
        'languageserver', \
        'NOAA-FIMS/FIMS', \
        'nmfs-ost/asar', \
        'nmfs-ost/stockplotr', \
        'renv' \
    ))"

# Print a message when the build is done
RUN cat << EOF
******************************************************************
* Build complete! Your FIMS environment is ready.
* Start the container using 'docker compose up -d'.
* Open the container using 'docker exec -it fims_r_container bash'.
* If you see 'root@xxx:/workspaces/fims_configuration#' in the terminal,
  then you are inside the container.
* Type 'R' in the terminal to open an R session.
* Run 'renv::init()' in the R console to create reproducible environments
  for your R projects. Learn more about renv:
  https://rstudio.github.io/renv/articles/renv.html
* To quit R and exit the container, use 'q()' and 'exit'.
* To know you are out of the container you should see 'user@xxx:~/path$'.
* To delete the container and rebuild, stop the container then remove the
  container and the cache:
  'docker compose down'
  'docker builder prune --all'
******************************************************************

EOF

USER root
