#!/bin/sh

# Print the current Node.js version
node -v

# Install the specified version of npm globally
sudo npm install -g npm@"${NPM_VERSION}" --force

# Print the updated npm version
npm -v