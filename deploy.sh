#!/bin/bash

source .env

forge script script/Deploy.s.sol:DeployScript --rpc-url https://lisk.drpc.org --broadcast --verify