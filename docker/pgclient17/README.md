# macnettj/pgclient17

The point of this is to provide a quick way of using the psql command-line interface for postgresql 15 in docker.  The most common use cases I have for this are:
- connecting/working on a postgresql instance hosted in a kubernetes cluster, or 
- connecting/working on a postgresql cloud-hosted instance that's networked to allow access to a cloud k8s cluster (AKS, EKS), but does not allow connectivity outside of said k8s cluster

## Versions
There are currently two versions of this available, which can be catered to your own situation:
- ubuntu (22.04)

## Prebuilt copies of image
These are available at https://hub.docker.com/r/macnettj/pgclient17

## Execution
Both of the examples below spin the container up as interactive/terminal mode.

Docker:
`docker run --rm -it --name mypgclient macnettj/pgclient15:ubuntu`

Kubernetes (interactive):

`kubectl run -i -t mypgclient --image=macnettj/pgclient15 --restart=Never --rm`