#!/bin/sh
export HUB=$(kubectl --namespace default get po | grep '^hub-' | cut -d' ' -f 1 )
kubectl --namespace default cp $1 $HUB:$2