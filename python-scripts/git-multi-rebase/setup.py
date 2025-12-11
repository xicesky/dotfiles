from setuptools import find_packages, setup

setup(
    name='git-multi-rebase',
    version='0.1.0',
    packages=find_packages(),
    install_requires=[
        'GitPython',
    ],
    entry_points='''
        [console_scripts]
        git-multi-rebase=gitmultirebase.cli:cli
    ''',
)
