OrgChartGen
===========

Generate an iPraktikum-style OrgChart from the given directory structure, i.e.
using “Convention over Configuration.”

### Usage

`OrgChartGen.app/Contents/MacOS/OrgChartGen [-path PATH] [-version VERSION]`  
If no arguments are passed, a GUI will be presented.

### Concepts

The file name of an image without extension specifies its caption.  
If the file name contains an underscore `_`, everything before the first `_` is
ignored and can therefore be used to specify an order via a sequence number.  
If the file name contains more than one `_`, the text after the second `_` may
be used as subcaption override, where appropriate. Additional `_` trigger line
breaks.

Directory names are taken as is, except for team directory names which also
support the `_`.

### Folder structure

-   `CustomerLogos`

    -   `Teamname.ext` (must match with team folder name)

-   `Pictures`

    -   `Cross Project`

        -   `3_Coach` (coach instructors)

        -   `4_Modeling` (modeling coordinators and coaches)

        -   `5_Release Mgmt` (release management coordinators and coaches)

        -   `6_Merge Mgmt` (merge management coordinators and coaches)

    -   `Infrastructure` (infrastructure providers)

    -   `Program Management` (program managers)

    -   `Teams`

        -   `Teamname`

            -   `1_Customer` (customers)

            -   `2_Project Leader` (project leaders)

            -   `3_Coach` (team coaches)

            -   `4_Modeling` (team members with modeling role)

            -   `5_Release Mgmt` (team members with release management role)

            -   `6_Merge Mgmt` (team members with merge management role)

            -   `9_Team` (team members without cross-project role)

### Output

The output is written to the input directory.

-   `org_chart.css`, `org_chart.htm` (HTML5 version)

-   `org_chart.pdf` (PDF version generated from the HTML)

### Dependencies

-   [GRMustache.swift, 1.0.1](https://github.com/groue/GRMustache.swift/)  
    MIT  
    *via CocoaPods*
