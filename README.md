# WebLogicDocker
[<img src="https://img.shields.io/badge/Dockerfile-build-orange.svg?logo=Docker">]

## Getting started

To set up your environment for Oracle WebLogic Server, follow these steps:

    **Subscription Requirement:**
        To download the necessary files from Oracle, ensure you have a valid subscription, which is required for access.

    **Download Oracle WebLogic Server Slim:**
        In your repository, download the Oracle WebLogic Server Slim edition. Refer to the URL in the file: _WLS/fmw_14.1.1.0.0_wls_lite_slim_Disk1_1of1.zip.download_.

    **Download OPatch and WebLogic Patches:**
        Download the required OPatch and WebLogic patches. Save these patches to the _WLS/Patches_ folder.

    **Application Deployment:**
        In the _DeployApp_ folder, place the WAR or EAR file of your compiled application. Be sure to make the necessary modifications to the _datasource.properties_ file with your credentials and the database endpoint.

    **Dockerfile Modifications:**
        If you need to add or remove components or configurations, make the appropriate modifications to the Dockerfile. This file controls the setup and configuration of your Docker image.

By following these steps, you can create an environment for Oracle WebLogic Server, deploy your applications, and make any necessary Dockerfile adjustments to meet your specific requirements.
