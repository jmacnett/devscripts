# macnettj/pgclient14

The point of this is to provide a quick way of using the psql command-line interface for postgresql 14 in docker.  The most common use cases I have for this are:
- connecting/working on a postgresql instance hosted in a kubernetes cluster, or 
- connecting/working on a postgresql cloud-hosted instance that's networked to allow access to a cloud k8s cluster (AKS, EKS), but does not allow connectivity outside of said k8s cluster

## Versions
There are currently two versions of this available, which can be catered to your own situation:
- alpine (3.18): very small, quick to spin up, but limited by alpine repos if you need other tools.
- ubuntu (20.04): heavier, but apt has pretty extensive offerings in terms of other packages available for use.

## Execution
Both of the examples below spin the container up as interactive/terminal mode.

Docker:
`docker run --rm -it --name mypgclient macnettj/pgclient14:ubuntu`

Kubernetes (interactive):

`kubectl run -i -t mypgclient --image=macnettj/pgclient14 --restart=Never --rm`