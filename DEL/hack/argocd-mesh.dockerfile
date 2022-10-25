# docker build --platform linux/arm64 -f argocd-mesh.dockerfile . -t kodacd/argocd:v2.5.0-rc2 && docker push kodacd/argocd:v2.5.0-rc2
FROM argoproj/argocd:v2.5.0-rc2

# Switch to root for the ability to perform install
USER root

# Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests 
# (e.g. curl, awscli, gpg, sops)
RUN apt-get update && \
    apt-get install -y \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

    # docker build --platform linux/arm64 -f argocd-mesh.dockerfile

# Switch back to non-root user
USER 999