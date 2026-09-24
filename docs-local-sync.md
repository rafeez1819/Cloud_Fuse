# CloudFuse local desktop-sync mode

CloudFuse can use folders managed by Google Drive for desktop, OneDrive, or Dropbox on the same Windows machine. This mode does not require creating a Google Cloud OAuth client.

## How it works

CloudFuse reads and writes the synchronized folder through the Windows filesystem. The provider desktop client is responsible for synchronizing those bytes with the cloud account.

## Connect

In Drive settings, choose the provider and use the local-folder mode. Enter a real path such as:

- `G:\\My Drive\\CloudFuseStorage`
- `C:\\Users\\<user>\\OneDrive\\CloudFuseStorage`
- `C:\\Users\\<user>\\Dropbox\\CloudFuseStorage`

The CloudFuse server must be running on the same Windows machine and under a Windows account that can access the folder.

## Important

This mode is not provider-API OAuth. It relies on the desktop sync client already being signed in. CloudFuse therefore cannot guarantee cloud quota from the provider API; its quota display uses filesystem capacity reported for the connected folder's volume.

For distributed large files, CloudFuse stores its physical chunk files under a hidden `.cloudfuse` directory inside each connected sync folder and keeps the logical file/manifest in its database.
