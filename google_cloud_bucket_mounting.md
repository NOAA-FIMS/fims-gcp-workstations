# Instructions for mounting Google Cloud Storage bucket

[← Back to main README](README.md)

Paste all of this code in the terminal and follow the instructions to authenticate your google account.  

## Define your bucket and the mount point
The `$HOME` symbol is a shortcut for your home directory, so this will
create the folder at /home/your_username/my_gcs_bucket. This may be different
than your GitHub repo directory. You can use the command `pwd` to see where you currently
are and `cd ..` to go up a level where then you can run `mkdir -p "MOUNT_POINT"` or
`mkdir -p $HOME/my_gcs_bucket`

```bash
BUCKET_NAME="fims-assessment-model-comparison-io-data"
MOUNT_POINT="$HOME/my_gcs_bucket"
```

## Authentication
This command authenticates your user account with Google Cloud.
You'll be prompted to open a browser to complete the login process.
```bash
echo "Running gcloud authentication. Please follow the instructions to log in in your browser."
gcloud auth application-default login
```

> **Note:** You will see the following warning but you can ignore it:
```bash
WARNING: 
Cannot find a quota project to add to ADC. You might receive a "quota exceeded" or 
"API not enabled" error. Run $ gcloud auth application-default set-quota-project to add a quota project.
```

## Installation and Setup (Run only once)
- Create the mount point if it doesn't exist.
- Since this directory is in your home folder, you don't need `sudo` to create it.
- After creating this directory, you need to mount it first before adding any files to it.
```bash
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
fi
```
- Add the Google Cloud GPG key to your system's trusted keys.
- This is a critical step to verify the authenticity of the packages.
```bash
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/gcsfuse.gpg
```

- Add the GCS FUSE repository to your system's sources list.
```bash
echo "deb [signed-by=/etc/apt/trusted.gpg.d/gcsfuse.gpg] https://packages.cloud.google.com/apt gcsfuse-`lsb_release -c -s` main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list > /dev/null
```

- Update the package list to include the new repository.
```bash
echo "Updating package list..."
sudo apt-get update
```

- Install gcsfuse.
```bash
echo "Installing gcsfuse..."
sudo apt-get install -y gcsfuse
```

## Mounting the Bucket (you might only need to run this if restarting a workstation)
- Use the gcsfuse tool to mount the bucket to the specified mount point.
- The mount point is in your home directory, so `sudo` is no longer needed.
```bash
echo "Mounting the bucket..."
gcsfuse --implicit-dirs "$BUCKET_NAME" "$MOUNT_POINT"

echo "Mounting complete. You can now access the bucket contents at $MOUNT_POINT"
```

- Optional: List the contents to verify the mount was successful.
```bash
ls -l "$MOUNT_POINT"
```

- Simply treat the mounted directory ($HOME/my_gcs_bucket) like any other folder
 on your local file system. The $HOME directory may be one above you GitHub
 repo directory, so you can't just add a new folder in that directory.
    - To save a new file: Save it directly into the mount point, e.g., 
    cp /path/to/my_local_file.txt $HOME/my_gcs_bucket/.
    - To create files directly: In your R, Python, or other code, set the output 
    path to a location within the mounted directory, e.g., 
    output_path = "/home/your_user/my_gcs_bucket/results/output.csv".
