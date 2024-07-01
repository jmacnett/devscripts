# macnettj/redis-cli

The point of this is to provide a quick way of using the redis-cli command-line interface in docker.  The most common use cases I have for this are:
- connecting/working on a redis instance hosted in a kubernetes cluster, or 
- connecting/working on a redis cloud-hosted instance that's networked to allow access to a cloud k8s cluster (AKS, EKS), but does not allow connectivity outside of said k8s cluster

## Versions
- ubuntu (22.04)

## Prebuilt copies of image
These are available at https://hub.docker.com/r/macnettj/redis-cli

## Execution
Both of the examples below spin the container up as interactive/terminal mode.

Docker:
`docker run --rm -it --name myrediscli macnettj/redis-cli:ubuntu`

Kubernetes (interactive):

`kubectl run -i -t myrediscli --image=macnettj/redis-cli --restart=Never --rm`