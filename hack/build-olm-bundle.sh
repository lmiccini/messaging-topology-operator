# Script to build an OLM bundle (Operator Lifecycle Manager)
# NOTE: requires operator-sdk

set -x
rm -Rf bundle bundle.Dockerfile
make manifests
operator-sdk generate kustomize manifests -q
#cd config/manager && kustomize edit set image controller=rabbitmq-cluster-operator:latest
kustomize build config/manifests | operator-sdk generate bundle --overwrite --verbose --use-image-digests
#FIXME: look into why scorecard isn't being deactivated
sed -e '/.*scorecard/d' -i bundle.Dockerfile
operator-sdk bundle validate ./bundle

echo "Listing..."
ls bundle/manifests
