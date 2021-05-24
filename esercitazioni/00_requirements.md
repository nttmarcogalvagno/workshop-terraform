# Setting up GCP

Create project on gcp: (open up a free account if needed)
![gcp-new-prj.PNG](./_resources/9e82d3e69be01eba0f7550d1edd599e1.png)

Click drop-down

![gcp-new-prj-1.PNG](./_resources/d4812f6777a14b07c6efb1b7b1aae431.png)
Click 'New Project'

![gcp-new-prj-2.PNG](./_resources/4b72d4a58bef054aa6f9124f10c3d1c8.png)
Project is created, Dashboard is presented.

![gcp-new-prj-3.PNG](./_resources/45f0f4245236f55877fa2c8a08447d8a.png)

1 Click upper left corner  --> 2 IAM and Admin --> 3 Service Account (Account di Servizio)

![gcp-new-prj-4.PNG](./_resources/efa1454a1764c62be4edc1aeb10c5ed8.png)

Select the project you created in the previous step.

- Under **Service account**, select **New service account**.
- Give it any name you like.
- For the **Role**, choose **Project -> Editor**.
- Leave the **Key Type** as JSON.
- Click **Create** to create the key and save the key file to your system.


Download the generated JSON file and save it to the directory of your project.

![image.png](./_resources/8156f0de70338290a2bf072838af278b.png)

Enable the following APIs on the project where your VPC resides:
Go to:

- Compute Engine API → [*https://console.cloud.google.com/apis/library/compute.googleapis.com*](https://console.cloud.google.com/apis/library/compute.googleapis.com)
- Cloud Resource Manager API → [*https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com*](https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com)

And click 'Enable' button.
GCP part of the Lab ends here.