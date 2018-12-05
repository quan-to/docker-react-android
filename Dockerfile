FROM ubuntu:18.04

ENV BUILD_TOOLS_VERSION=28.0.3 
ENV ANDROID_SDK_VERSION=android-28
ENV DEBIAN_FRONTEND=noninteractive
ENV BASE_DEPS="openjdk-8-jdk wget expect git curl s3cmd gpg build-essential imagemagick librsvg2-bin ruby ruby-dev wget libcurl4-openssl-dev git"
ENV NODE_DEPS=nodejs
# ------------------------------------------------------
# --- Install required tools

RUN apt-get update -qq
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy $BASE_DEPS

# ------------------------------------------------------
# --- Download Android SDK tools into $ANDROID_SDK_HOME

RUN useradd -u 1000 -M -s /bin/bash android
RUN chown 1000 /opt

USER android
ENV ANDROID_SDK_HOME /opt/android-sdk-linux
ENV ANDROID_HOME /opt/android-sdk-linux


RUN cd /opt && wget -q https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz -O android-sdk.tgz
RUN cd /opt && tar -xvzf android-sdk.tgz
RUN cd /opt && rm -f android-sdk.tgz

ENV PATH ${PATH}:${ANDROID_SDK_HOME}/tools:${ANDROID_SDK_HOME}/platform-tools:${ANDROID_SDK_HOME}/tools/bin:${PATH}"

RUN echo y | sdkmanager --install 'ndk-bundle'
RUN echo y | sdkmanager --licenses

ENV PATH ${PATH}:${ANDROID_SDK_HOME}/tools:${ANDROID_SDK_HOME}/platform-tools:/opt/tools


# ------------------------------------------------------
# --- Install Android SDKs and other build packages

RUN echo y | android update sdk --no-ui --all --filter platform-tools | grep 'package installed'



# SDKs
RUN echo y | android update sdk --no-ui --all --filter $ANDROID_SDK_VERSION | grep 'package installed'

# Build tools
RUN echo y | android update sdk --no-ui --all --filter build-tools-$BUILD_TOOLS_VERSION | grep 'package installed'

# Extras
RUN echo y | android update sdk --no-ui --all --filter extra-android-m2repository | grep 'package installed'
RUN echo y | android update sdk --no-ui --all --filter extra-google-m2repository | grep 'package installed'
RUN echo y | android update sdk --no-ui --all --filter extra-google-google_play_services | grep 'package installed'

# Copy install tools
COPY tools /opt/tools

#Copy accepted android licenses
COPY licenses ${ANDROID_SDK_HOME}/licenses

# Update SDK
RUN /opt/tools/android-accept-licenses.sh android update sdk --no-ui --obsolete --force

USER root

RUN echo "Installing Node.JS" \
	&& curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN echo "Installing Additional Libraries" \
	 && rm -rf /var/lib/gems \
	 && apt-get update && apt-get install $NODE_DEPS -qqy --no-install-recommends

RUN echo "Installing Fastlane" \
	&& gem install fastlane badge -N \
	&& gem cleanup

# Install React Dependencies
RUN npm i -g yarn react-native-cli
RUN apt-get clean

VOLUME ["/opt/android-sdk-linux"]
