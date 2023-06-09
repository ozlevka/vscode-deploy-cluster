# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

ARG KUBECTL_VERSION="v1.26.5"
ARG HELM_VERSION="v3.12.0"

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID



ENV DEBIAN_FRONTEND=noninteractive

# Install necessary tools
RUN apt-get update && apt-get install -y curl apt-transport-https gnupg ca-certificates apt-utils vim git fish tmux \
    && curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ \
    && ARCHITECTURE=$(dpkg --print-architecture) \
    && curl -L https://update.code.visualstudio.com/1.78.0/linux-deb-$(if [ "${ARCHITECTURE}" = "arm64" ]; then echo "arm64"; elif [ "${ARCHITECTURE}" = "amd64" ]; then echo "x64"; fi)/stable -o code_${ARCHITECTURE}.deb \
    && dpkg -i code_${ARCHITECTURE}.deb || true \
    && apt-get install -fy \
    # Install kubectl
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${ARCHITECTURE}/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/bin/ \
    # Install helm 
    && curl -L -o /tmp/helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCHITECTURE}.tar.gz \
    && cd /tmp && tar xzf helm.tar.gz \
    && mv linux-${ARCHITECTURE}/helm /usr/local/bin/helm && chmod +x /usr/local/bin/helm \
    # Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER vscode
WORKDIR /home/vscode

# Install extensions
RUN code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
