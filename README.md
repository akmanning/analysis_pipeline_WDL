# TOPMed Analysis Pipeline — WDL Version

[![WDL 1.0 shield](https://img.shields.io/badge/WDL-1.0-lightgrey.svg)](https://github.com/openwdl/wdl/blob/main/versions/1.0/SPEC.md)  
This is a work-in-progress project to implement some components of the University of Washington [TOPMed pipeline](https://github.com/UW-GAC/analysis_pipeline) into Workflow Description Lauange (WDL) in a way that closely mimics [the CWL version of the UW Pipeline](https://github.com/UW-GAC/analysis_pipeline_cwl). In other words, this is a WDL that mimics a CWL that mimics a Python pipeline. All three pipelines use the same underlying R scripts which do most of the heavy lifting, making their results directly comparable.

## Features
* This pipeline is very similiar to the CWL version, and while the main differences between the two [are documented](https://github.com/DataBiosphere/analysis_pipeline_WDL/blob/main/_documentation_/for%20users/cwl-vs-wdl-user.md), testing indicates they are functionally equivalent -- so much so that files generated by the CWL are used as truth files for the WDL   
* As it works in a Docker container, it does not have any external dependencies other than the usual setup required for [WDL](https://software.broadinstitute.org/wdl/documentation/quickstart) and [Cromwell](http://cromwell.readthedocs.io/en/develop/)
* Contains a checker workflow for validating a set of known inputs and expected outputs

## Usage
Example files are provided in `test-data-and-truths` and in `gs://topmed_workflow_testing/UWGAC_WDL/`.  

The original pipeline had arguments relating to runtime such as `ncores` and `cluster_type` that do not apply to WDL. Please familarize yourself with the [runtime attributes of WDL](https://cromwell.readthedocs.io/en/stable/RuntimeAttributes/) if you are unsure how your settings may transfer. For more information on specific runtime attributes for specific tasks, see [the further reading section](https://github.com/DataBiosphere/analysis_pipeline_WDL/main/README.md#further-reading).  

### Terra users
For Terra users, it is recommended to import via Dockstore. Importing the correct JSON file for your workflow at the workflow field entry page will fill in test data and recommended runtime attributes for said test data. For example, load `vcf-to-gds-terra.json` for `vcf-to-gds.wfl`. If you are using your own data, please be sure to increase your runtime attributes appropriately.  

### Local users
Cromwell does not manage resources well on local executions -- parameters such as `memory` and `disks` get ignored when Cromwell detects it is not running on the cloud. As a result, these pipelines (LD pruning especially) may get their processes killed by your OS for hogging too much memory, or completely lock up Docker, even on a relatively powerful machine running on downsampled test data. That being said, preliminary testing of these pipelines is performed on a local machine running OSX Catalina, so while we cannot officially support this method of execution, the only thing really blocking it from running smoothly on a local machine is Cromwell's resource management and the power needed by some of these algorithms. These issues can *generally* be avoided by changing the concurrent job limit in your Cromwell configuration. [See instructions here](https://docs.dockstore.org/en/develop/getting-started/getting-started-with-wdl.html) for how to set it in the Dockstore CLI.

## Further reading
* [checker workflows](https://github.com/DataBiosphere/analysis_pipeline_WDL/blob/main/_documentation_/for%20users/checker.md)
* [ld-pruning](https://github.com/DataBiosphere/analysis_pipeline_WDL/blob/main/ld-pruning/README.md)
* [null-model](https://github.com/DataBiosphere/analysis_pipeline_WDL/blob/main/null-model/README.md)
* [vcf-to-gds](https://github.com/DataBiosphere/analysis_pipeline_WDL/blob/main/vcf-to-gds/README.md)
* [pc-air](https://github.com/DataBiosphere/analysis_pipeline_WDL/blob/main/pc-air/README.md


------

#### Author
Ash O'Farrell (aofarrel@ucsc.edu)  
