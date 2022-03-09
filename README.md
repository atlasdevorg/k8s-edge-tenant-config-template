# k8s-config-edge

This is a "template" repository. It is used as part of the edge setup process to generate a new repository for a customer.

# Variables
Each variable in the template is wrapped in double underscores so atlascontainerrepository becomes ____atlascontainerrepository____

atlascontainerrepository -> default to our container repository, but we could host our containers in a customer repo if required

envimagetag -> a tag part we add when tagging docker images available for that environment e.g. test for 1.0.0-test.0


clustername -> the name of the cluster (e.g. main)

devicename -> name of the edge iot device (normally what we call it on )
