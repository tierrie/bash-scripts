#!/usr/bin/python3

import sys, os, json, getopt, urllib.request; 

server_binary_directory = "/opt/minecraft/server_binaries"

# supported options 
# -w or --world <name> : update this instance's minecraft_server.jar
# -v or --version <version name> : if specified ,download this specific version of the binary instead of the latest
try:
  opts, args = getopt.getopt(sys.argv[1:],"hw:v:",["world=","version=","eula="])
except getopt.GetoptError as err:
  print(err)
  print("%s -w <world> -v <server version>" % sys.argv[0])
  sys.exit(2)

world = None
version = None
for opt, arg in opts:
  if opt == '-h':
    print("%s -w <world> -v <server version>" % sys.argv[0])
    sys.exit()
  elif opt in ("-w", "--world"):
    world = arg
    print("Updating the minecraft server for %s" % world)
  elif opt in ("-v", "--version"):
    version = arg
    print("Downloading the minecraft server version %s" % version)
  elif opt in ("--eula"):
    eula = arg
    print("Setting EULA to %s" % eula)


# download and search for the latest version of the minecraft server
manifest_url="https://launchermeta.mojang.com/mc/game/version_manifest.json"
print("Requesting manifest from %s" % manifest_url)
req = urllib.request.urlopen(manifest_url)
res = req.read()
manifest = json.loads(res)


if (version):
  target_release = version
else:
  target_release = manifest['latest']['release']
  print("Latest version of Minecraft Server is %s" % target_release)

# find the url of the latest version (meta file)
for version in manifest['versions']:
  if (version['id'] == target_release):
    version_url = version['url']
    print("Latest version download urls available at %s" % version_url)


# request the release package meta file
print("Requesting download urls from %s" % version_url)
req = urllib.request.urlopen(version_url)
res = req.read()
release = json.loads(res)
download_server_url = release['downloads']['server']['url']
print("Server binaries for %s available at %s" % (target_release, download_server_url))


# check if path exists, if not, create it
if (not os.path.exists(server_binary_directory)):
  print("Creating server binary repository at %s" % server_binary_directory)
  os.mkdir(server_binary_directory, 0o755)

# download the jar to /opt/minecraft/server_binaries/minecraft_server_{version}.jar
print("Beginning download of %s" % download_server_url)
server_download_path = server_binary_directory + "/minecraft_server_" + target_release + ".jar"
urllib.request.urlretrieve(download_server_url, server_download_path)
print("Downloaded binaries to %s" % server_download_path)

# if there is a specific world that needs to be updated with this binary
if (world):
  # create symbolic links to the necessary directory  
  instance_path = "/opt/minecraft/instances/" + world
  instance_binary_path = instance_path + "/minecraft_server.jar"

  # if instance path doesn't exist, create it
  if (not os.path.exists(instance_path)):
    os.mkdir(instance_path, 0o755)
    
  # if symoblic link exists, recreate it
  if (os.path.exists(instance_binary_path)):
    print("Symbolic link exists, deleting symbolic link")
    os.remove(instance_binary_path)
    
  # create symbolic link
  print("Creating symbolic link from %s to %s" % (server_download_path, instance_binary_path))
  os.symlink(server_download_path, instance_binary_path)
  
  # if eula is not accepted, accept eula
  eula_path = instance_path + "/eula.txt"
  if (eula):
    print("Updating EULA")
    f=open(eula_path, "w+")
    f.write(eula)
    f.close()
    

