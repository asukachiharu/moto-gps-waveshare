"""Prepare pinned official SDK frameworks in ignored ios/Vendor.

AMapNaviKit includes MAMapKit; never link the separate MAMapKit framework.
The official archive has device arm64 and Intel simulator slices. We link SDKs
only for iphoneos; Apple-silicon simulators report SDK unavailable; they do not simulate navigation.
"""
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import subprocess
import sys
from urllib.request import Request, urlopen
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / 'platforms/ios/Vendor'
DEST = VENDOR / 'Frameworks'
ALLOWED = {'AMapNaviKit.framework','AMapFoundationKit.framework','AMapSearchKit.framework'}


def extract(archive):
    total = 0
    with zipfile.ZipFile(archive) as package:
        for item in package.infolist():
            parts = PurePosixPath(item.filename).parts
            if not parts or parts[0] not in ALLOWED:
                continue
            total += item.file_size
            if total > 1_000_000_000 or stat.S_ISLNK(item.external_attr >> 16):
                raise ValueError('Unsafe SDK archive')
            output = (DEST / item.filename).resolve()
            if not output.is_relative_to(DEST.resolve()):
                raise ValueError('SDK archive path escapes destination')
            if item.is_dir():
                output.mkdir(parents=True,exist_ok=True)
            else:
                output.parent.mkdir(parents=True,exist_ok=True)
                with package.open(item) as source, output.open('wb') as target:
                    import shutil
                    shutil.copyfileobj(source,target,1024*1024)


def prepare():
    # Fetch only the required official libraries, not the 272 MB example bundle.
    libraries = json.loads((ROOT/'platforms/ios/amap-libraries-manifest.json').read_text())['libraries']
    for item in libraries:
        library = VENDOR/'Packages'/item['file']
        download(item, library)
        extract(library)
    manifest = json.loads((ROOT/'platforms/ios/amap-search-manifest.json').read_text())
    search = VENDOR / 'AMapSearch-official.zip'
    download(manifest, search)
    extract(search)
    for name in ALLOWED:
        binary = DEST/name/name.removesuffix('.framework')
        if not binary.is_file():
            raise ValueError('Missing official framework: '+name)
    print('Official SDKs prepared: Navi 11.3.100 / Foundation 1.9.4 / Search 9.8.1; no key printed')


def download(item, output):
    output.parent.mkdir(parents=True,exist_ok=True)
    if not output.exists():
        partial = output.with_suffix('.part')
        print('Downloading verified official SDK: '+output.name,flush=True)
        subprocess.run(['curl','--fail','--location','--ipv4','--connect-timeout','10',
                        '--max-time','300','--retry','2','--retry-delay','3',
                        '--max-filesize',str(item['bytes']+1),'--output',str(partial),item['url']],check=True)
        partial.replace(output)
    if output.stat().st_size != item['bytes'] or hashlib.sha256(output.read_bytes()).hexdigest() != item['sha256']:
        raise ValueError('Official SDK changed; review manifest before use: '+output.name)


if __name__ == '__main__':
    prepare()
