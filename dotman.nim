import os, strutils, sequtils, osproc, memfiles

let
  manifestFile = "df-manifest"
  fileDir = getCurrentDir() / "dotfiles"  # your repo structure

proc expandPath(path: string): string =
  # Expands $HOME to /home/youruser
  result = path
  if "$HOME" in path:
    result = result.replace("$HOME", getHomeDir())

proc readManifest(): seq[(string, string)] =
  # Reads manifest into (repoFileName, systemPath) pairs
  result = @[]
  for line in lines(memfiles.open(manifestFile)):
    let cleaned = line.split("#")[0].strip()  # allow inline comments
    if cleaned.len == 0: continue
    let parts = cleaned.splitWhitespace()
    if parts.len != 2:
      echo "⚠️ Invalid manifest line: ", line
      continue
    result.add((parts[0], expandPath(parts[1])))

proc deployFiles(pairs: seq[(string, string)]) =
  for (repoName, systemPath) in pairs:
    let src = fileDir / repoName
    let dst = systemPath

    if not fileExists(src):
      echo "⚠️  Repo file missing: ", src
      continue

    let dstDir = dst.splitPath.head
    if not dirExists(dstDir):
      createDir(dstDir)

    if fileExists(dst):
      removeFile(dst)

    copyFile(src, dst)
    echo "✅ Deployed: ", repoName, " → ", dst

proc retrieveFiles(pairs: seq[(string, string)]) =
  for (repoName, systemPath) in pairs:
    let src = systemPath
    let dst = fileDir / repoName

    if not fileExists(src):
      echo "⚠️  System file missing: ", src
      continue

    let dstDir = dst.splitPath.head
    if not dirExists(dstDir):
      createDir(dstDir)

    if fileExists(dst):
      removeFile(dst)

    copyFile(src, dst)
    echo "📥 Retrieved: ", src, " → ", repoName

when isMainModule:
  let args = commandLineParams()
  if args.len != 1 or args[0] notin ["deploy", "retrieve"]:
    echo "Usage: dotman [deploy|retrieve]"
    quit(1)

  let pairs = readManifest()

  case args[0]
  of "deploy" or "yeet":
    deployFiles(pairs)
  of "retrieve":
    retrieveFiles(pairs)
