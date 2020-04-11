# Azure Policy and Governance Pipeline Tasks

[![Visual Studio Marketplace Version](https://img.shields.io/visual-studio-marketplace/v/razorspoint.rp-build-release-azurepolicy)](https://marketplace.visualstudio.com/items?itemName=razorspoint.rp-build-release-azurepolicy)
![Visual Studio Marketplace Installs - Azure DevOps Extension](https://img.shields.io/visual-studio-marketplace/azure-devops/installs/total/razorspoint.rp-build-release-azurepolicy)
[![Visual Studio Marketplace Rating](https://img.shields.io/visual-studio-marketplace/r/razorspoint.rp-build-release-azurepolicy)](https://marketplace.visualstudio.com/items?itemName=razorspoint.rp-build-release-azurepolicy&ssr=false#review-details)
[![Twitter URL](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/RazorSPoint) [![Twitter Follow](https://img.shields.io/twitter/follow/RazorSPoint.svg?style=social&label=Follow)](https://twitter.com/RazorSPoint)

This extension is hosted on the Visual Studio Marketplace for Azure DevOps and helps you to deploy Azure Policies into your Azure tenant.
Detailed documentation can be found on the [GitHub Pages](https://razorspoint.github.io/azure-devops-azure-policy-extension).

## Pipeline Status

![Azure DevOps tests](https://img.shields.io/azure-devops/tests/razorspoint/RP_Build-Release-AzurePolicy/19?label=unit%20tests)
![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/razorspoint/RP_Build-Release-AzurePolicy/19?label=code%20coverage)

|         Stage                       |             Status           | History |
|-------------------------------------|------------------------------|---------|
| Overall                               | [![Build status](https://img.shields.io/azure-devops/build/razorspoint/3809133c-f9cd-4d0d-8e63-d1953bedc6cf/19?label=Pipeline%20General)](https://dev.azure.com/razorspoint/RP_Build-Release-AzurePolicy/_build/latest?definitionId=19&branchName=master)|[![Azure DevOps Build History](https://buildstats.info/azurepipelines/chart/RazorSPoint/RP_Build-Release-AzurePolicy/19?branch=master&includeBuildsFromPullRequest=false)](https://dev.azure.com/RazorSPoint/RP_Build-Release-AzurePolicy/_build/latest?definitionId=19&branchName=master)|
| Build                               | [![Build status](https://img.shields.io/azure-devops/build/razorspoint/3809133c-f9cd-4d0d-8e63-d1953bedc6cf/19?label=Build&stage=Build)](https://dev.azure.com/RazorSPoint/RP_Build-Release-AzurePolicy/_build/latest?definitionId=19&branchName=master)||
| Marketplace Test Release   | [![Environment status](https://img.shields.io/azure-devops/build/razorspoint/3809133c-f9cd-4d0d-8e63-d1953bedc6cf/19?label=Staging&stage=Staging)](https://dev.azure.com/RazorSPoint/RP_Build-Release-AzurePolicy/_build/latest?definitionId=19&branchName=master) ||
| Marketplace Live Release   | [![Environment status](https://dev.azure.com/razorspoint/RP_Build-Release-AzurePolicy/_apis/build/status/RazorSPoint.azure-devops-azure-policy-extension?branchName=master&stageName=Production)](https://dev.azure.com/RazorSPoint/RP_Build-Release-AzurePolicy/_build/latest?definitionId=19&branchName=master) ||

## Contributing

Contributions are very much welcome no matter how small they are!

Just go ahead and fork the repo and raise a pull request. Additionally you can also

1. Check the Issues page and start contributing to one of the suggested issues.
2. If you have an new suggestion then raise an issue or comment on an existing issue with what you want to contribute.
3. Just align shortly with me on the issue. If you want you can go right ahead but to not make unnecessary commit it would be easier to align before coding.
4. Include a link to the issue in your pull request.
5. If it is a bug or an error, then you can create the pull request right away.

## Coding Guidelines

1. Follow the general best practice PowerShell coding guidelines
2. This repo uses PSScriptAnalyzer with the default ruleset. I would like to have no warnings and errors within the build!
3. Write unit tests with Pester for you code that you contribute.
