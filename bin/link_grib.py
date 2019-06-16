# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

import os
import shutil
import glob
import string
import itertools
import argparse

def link(src_path, link_path):
    assert os.path.isfile(src_path)
    if os.path.exists(link_path) or os.path.islink(link_path):
        os.remove(link_path)
    try:
        # Windows: requires admin rights, but not restricted to same drive
        os.symlink(src_path, link_path)
    except:
        # Windows: does not require admin rights, but restricted to same drive
        os.link(src_path, link_path)

def link_or_copy(src, dst):
    try:
        link(src, dst)
    except:
        # fall-back for Windows if hard/sym links couldn't be created
        shutil.copy(src, dst)

def generate_gribfile_extensions():
    letters = list(string.ascii_uppercase)
    for a, b, c in itertools.product(letters, repeat=3):
        yield a + b + c
    
def link_grib_files(input_dir, output_dir):
    for path in glob.glob(os.path.join(output_dir, 'GRIBFILE.*')):
        os.remove(path)
    paths = [os.path.join(input_dir, name) for name in os.listdir(input_dir)]
    for path, ext in zip(paths, generate_gribfile_extensions()):
        link_path = os.path.join(output_dir, 'GRIBFILE.' + ext)
        link_or_copy(path, link_path)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input', help='Folder with GRIB files')
    parser.add_argument('output', nargs='?', default=os.getcwd(),
                        help='Output folder, default is current directory')
    args = parser.parse_args()
    link_grib_files(args.input, args.output)
