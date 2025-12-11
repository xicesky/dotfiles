#!/usr/bin/env python3
import sys
import os
from dataclasses import dataclass
from git import Repo, Head, Commit

if sys.version_info[0] < 3 or sys.version_info[1] < 10:
    raise Exception("Python 3.10 or a more recent version is required.")

@dataclass
class RebaseInfo:
    """Contains all the information required for a multi-rebase"""
    repo: Repo
    base_branch: Head
    target_branches: list[Head]
    merge_base: Commit
    
    def get_new_commits(self) -> list[Commit]:
        return list(self.repo.iter_commits(rev=str(self.merge_base) + '..' + str(self.base_branch)))

def resolve_branch(repo: Repo, name: str) -> Head:
    if not name in repo.heads:
        raise Exception("Branch not found: " + name)
    return repo.heads[name]

def print_commits(commits):
    for commit in commits:
        print("%s %s" % (commit.hexsha, commit.message.splitlines()[0]))

def collect_rebase_info(base_branch: str, target_branches: list[str], repo_dir: str = "."):
    # Basic repo checks
    if not os.path.isdir(repo_dir):
        raise Exception("Repo directory not found: " + repo_dir)
    repo = Repo(repo_dir)
    if repo.bare:
        raise Exception("Cannot work with bare repo: " + repo_dir)
    if repo.is_dirty():
        raise Exception("Repo is dirty, please commit or stash first: " + repo_dir)
    
    # Find branches and merge-base
    #print("Heads:", repo.heads)
    base_head = resolve_branch(repo, base_branch)
    target_heads = [resolve_branch(repo, name) for name in target_branches]
    merge_base = repo.merge_base(base_head, *target_heads)[0]
    
    return RebaseInfo(repo, base_head, target_heads, merge_base)

def main(argv):
    # print("argv:", argv)
    # print("sys.version_info:", sys.version_info)
    
    script_name: str = argv.pop(0)
    
    # FIXME: Handle flags
    if len(argv) == 0:
        raise Exception("Missing argument: base branch")
    base_branch: str = argv.pop(0)
    
    target_branches: list[str] = []
    while len(argv) > 0:
        target_branches.append(argv.pop(0))
        pass
    
    if len(target_branches) == 0:
        raise Exception("One more target branches required")

    rebase_info: RebaseInfo = collect_rebase_info(base_branch, target_branches)
    print(rebase_info)
    print(f"New commits on {rebase_info.base_branch.name}:")
    print_commits(rebase_info.get_new_commits())
    
    return 0

def cli():
    try:
        sys.exit(main(sys.argv))
    except Exception as e:
        print("Error:", e)
        sys.exit(1)

if __name__ == '__main__':
    cli()
