# Model Comparison Project

This project uses a simulation-estimation approach to evaluate the reliability of five age-structured assessment models developed by NOAA Fisheries: the Age Structured Assessment Program (ASAP), the Assessment Model for Alaska (AMAK), the Beaufort Assessment Model (BAM), the Fisheries Integrated Modeling System (FIMS), and Stock Synthesis (SS3).

We provide two methods for replicating this analysis, allowing for a consistent and reproducible research environment.

1. The Docker environment
This method uses Docker to create a self-contained development environment with all required software pre-installed. The image includes R, specific system packages, all required R packages, and two web-based IDEs: RStudio Server and code-server (VS Code in the browser). This is the most reliable way to ensure the analysis runs correctly regardless of your local machine's configuration.

1. The local {renv} Environment
This method is for users who prefer to use their local R installation. It uses the {renv} package to restore a project-specific library of R packages from the renv.lock file, ensuring that the exact package versions used in the analysis are installed on your machine.
TODO: set up {renv} and then copy renv.lock, .Rprofile, renv/active.R to Dockerfile

## Docker quick start cheat sheet

This guide provides the step-by-step commands to set up and run the development environment using Docker.

1. Open a terminal and clone this project to your local machine, then navigate into the project directory.

```Bash
git clone https://github.com/NOAA-FIMS/fims-gcp-workstations.git
cd fims-gcp-workstations/model_comparison_with_fims
```

2. Build and start the container

```Bash
docker compose up -d --build
```

3. Start `code-server` 
```Bash
docker exec -d r_dev_container code-server --bind-addr 0.0.0.0:8080 /workspaces/model-comparison-project
```

- Find password: `code-server` automatically generates a password. To find it, run this commend:

```Bash
docker exec r_dev_container cat /root/.config/code-server/config.yaml
```

- Copy the password from the output.

- Install xdg-utils to open the web address in terminal.

```Bash
sudo apt update
sudo apt install xdg-utils
xdg-open http://localhost:8080
```

4. Install the R extension (ID: reditorsupport.r) from the Extensions view (Ctrl + Shift + X).

5. When you are finished working, you can stop the container by running the following command from your project directory:

```Bash
docker compose down
```