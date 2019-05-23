# cmdReporter-demo-bootstrapper
Automatically stand up a local Splunk enterprise trial with relevant addons and dashboards that will import data directly from the local /var/log/cmdreporter.log file.

**Note:**
The infosec application uses accelerated data models and data may not appear in the dashboards for up to 15 minutes depending on your hardware speed
This script will enable acceleration on all relevant data models in splunk, no action is required

**Usage:**
1) Download and run this script
2) Follow script prompts
3) There is no step 3

**Example Video:**  
[![cmdReporter Splunk Bootstrap Script Demo](https://img.youtube.com/vi/O2Tu_bAJL7A/0.jpg)](https://www.youtube.com/watch?v=O2Tu_bAJL7A)


```
Files Installed:  
Normal Splunk enterprise files plus:  
/Applications/Splunk  
├── etc  
│   ├── apps  
│   │   ├── InfoSec_App_for_Splunk  
│   │   ├── Splunk_SA_CIM  
│   │   ├── TA-cmdreporter  
│   │   ├── force_directed_viz  
│   │   ├── missile_map  
│   │   ├── punchcard_app  
│   │   ├── sankey_diagram_app  
```

