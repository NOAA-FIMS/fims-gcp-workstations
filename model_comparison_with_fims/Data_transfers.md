# How to transfer data to/from Google Cloud data buckets  

## Transfer from data bucket to Google Cloud Workstation  

1. Upload data or files from your computer to your data bucket. 

2. In your workstation open a terminal and type 

```{bash}
gcloud auth login
```

and proceed through the authentication steps. When you've authenticated, copy the url given into your terminal and hit `ENTER`. 

3. To begin the transfer, in the terminal run  

```{bash}
gcloud storage cp --recursive /home/user/<directory in workstation> gs://<data_bucket_name>
```

For example, if we want to transfer files from the data bucket `fims-assessment-model-comparison-io-data` to `fims-gcp-workstations/model_comparison_with_fims/data` it would look like: 

```{bash}
gcloud storage cp --recursive /home/user/fims-gcp-workstations/model_comparison_with_fims/data gs://fims-assessment-model-comparison-io-data
```

The `--recursive` is needed if you are copying a folder.  

## Transfer from Google Cloud Workstation to data bucket  

1. If you are in the same session, you do not need to authenticate again. Otherwise, run 

```{bash}
gcloud auth login
```
and complete the authentication process again.  

2. To transfer data from the workstation to your data bucket, in the terminal run: 

```{bash}
gcloud storage cp --recursive gs://<data_bucket_name> /home/user/<directory in workstation> 
```

or as the example above: 
```{bash}
gcloud storage cp --recursive gs://fims-assessment-model-comparison-io-data/meg_test  ./model_comparison_with_fims
```

To do the file transfer in R you can add the following code to an R script: 

```{r}
source_path <- "gs://fims-assessment-model-comparison-io-data/meg_test"

destination_path <- "./model_comparison_with_fims"

# Construct the arguments for the gcloud command
command <- "gcloud"

args <- c(
  # Specify the 'storage' component to interact with Google Cloud Storage.
  "storage",
  # Use the 'cp' (copy) command.
  "cp",
  # Add the flag to copy entire directories and their contents.
  "--recursive",
  source_path,
  destination_path
)

# Execute the command using system2()
# stdout = TRUE and stderr = TRUE capture the output from the terminal
# so you can see the progress or any errors within R.
result <- system2(
  command,
  args = args,
  stdout = TRUE,
  stderr = TRUE
)

```
