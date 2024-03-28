#!/usr/bin/env bash

kind delete cluster

kind create cluster --config kind.yaml

kubectl wait -A --for=condition=ready pod --field-selector=status.phase!=Succeeded --timeout=15m

kubectl get cm -n kube-system kube-proxy -o yaml | sed 's/maxPerCore.*/maxPerCore: 0/' | kubectl apply -n kube-system -f -

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.1/deploy/static/provider/kind/deploy.yaml

LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "address=/kind.cluster/$LB_IP"
