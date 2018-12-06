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

RUN cd /opt && wget -q https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip -O sdk-tools.zip
RUN cd /opt/android-sdk-linux && unzip -o /opt/sdk-tools.zip
RUN cd /opt && rm -f sdk-tools.zip

ENV PATH ${PATH}:${ANDROID_SDK_HOME}/tools:${ANDROID_SDK_HOME}/platform-tools:${ANDROID_SDK_HOME}/tools/bin:

RUN mkdir -p /opt/android-sdk-linux/.android/ && touch /opt/android-sdk-linux/.android/repositories.cfg

RUN yes | sdkmanager --licenses
RUN yes | sdkmanager 'ndk-bundle'


# ------------------------------------------------------
# --- Install Android SDKs and other build packages
RUN yes | sdkmanager 'platform-tools'

# SDKs
RUN yes | sdkmanager "platforms;$ANDROID_SDK_VERSION"

# Build tools
RUN yes | sdkmanager "build-tools;$BUILD_TOOLS_VERSION"

# Extras
RUN yes | sdkmanager "extras;android;m2repository"
RUN yes | sdkmanager "extras;google;m2repository"
RUN yes | sdkmanager "extras;google;google_play_services"

# Copy install tools
COPY tools /opt/tools

#Copy accepted android licenses
#COPY licenses ${ANDROID_SDK_HOME}/licenses

# Update SDK
RUN yes | sdkmanager --licenses

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
