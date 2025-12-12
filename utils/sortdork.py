import re
import json
import random
from typing import List, Dict
from collections import defaultdict

# Master patterns from our 500-list (key phrases to hybridize with)
MASTER_PATTERNS = [
    ' intext:"api_key" | "secret" | "token"',
    ' filetype:env "DB_PASSWORD" | "STRIPE_SECRET"',
    ' inurl:/graphql intext:"query" intext:"password"',
    ' site:*.vercel.app intext:"NEXT_PUBLIC_"',
    ' filetype:json "private_key" "BEGIN RSA"',
    ' inurl:/api/docs intext:"x-api-key"',
    ' site:*.supabase.co intext:"service_role key"',
    ' inurl:/.well-known/security.txt intext:"bounty"',
    ' filetype:yaml "kind: Secret"',
    ' inurl:/wp-json intext:"earnings" | "revenue"',
    # Add more from our list if you want; this seeds the hybrids
]

# Common mutators (operator swaps, boosters)
MUTATORS = [
    lambda d: re.sub(r'inurl:', 'intitle:', d) + ' -github',
    lambda d: d + ' site:*.edu | site:*.gov',
    lambda d: d + ' filetype:txt | filetype:pdf | filetype:sql',
    lambda d: d + ' intext:"password" | intext:"key" | intext:"secret"',
    lambda d: re.sub(r'site:', 'inurl:', d) + ' ext:php | ext:asp',
    lambda d: d + ' -demo -example -test',
    lambda d: d + ' intitle:"index of" "backup"',
    lambda d: re.sub(r'intitle:', 'intext:', d) + ' "admin" | "dashboard"',
    lambda d: d + ' OR "leak" OR "exposed"',
    lambda d: d + ' filter:media min_faves:10',  # X-style if blending
]

def extract_dorks(file_path: str) -> List[str]:
    """Extract and clean dorks from raw TXT dump."""
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Split on newlines, filter non-empty, strip junk
    lines = [line.strip() for line in content.split('\n') if line.strip()]
    
    # Regex to match dork-like patterns (starts with site:, inurl:, intitle:, etc.)
    dork_pattern = re.compile(r'^(site:|inurl:|intitle:|filetype:|intext:|"[^"]+")')
    dorks = [line for line in lines if dork_pattern.match(line) or 'inurl:' in line or 'intitle:' in line]
    
    # Dedup and sort
    dorks = list(set(dorks))
    dorks.sort()
    
    print(f"Extracted {len(dorks)} base dorks.")
    with open('base-extract.txt', 'w') as f:
        f.write('\n'.join(dorks))
    
    return dorks

def score_dork(dork: str) -> int:
    """Heuristic score 1-10: modern leaks high, legacy low."""
    score = 5  # Base
    if any(word in dork.lower() for word in ['api_key', 'secret', 'token', 'env', 'graphql', 'stripe', 'supabase']):
        score += 3
    if any(word in dork.lower() for word in ['login', 'admin', 'panel', 'owa']):
        score -= 2
    if 'filetype:json' in dork or 'private_key' in dork:
        score += 2
    return max(1, min(10, score))

def mutate_dork(base: str, num_mut: int = 30) -> List[Dict[str, str]]:
    """Generate mutations: 10 hybrids + 20 variants."""
    mutations = []
    
    # Hybridize with master patterns (pick random 10)
    for _ in range(10):
        hybrid = base + random.choice(MASTER_PATTERNS)
        mutations.append({'dork': hybrid, 'score': score_dork(hybrid), 'type': 'hybrid'})
    
    # Apply mutators (random 20)
    for _ in range(20):
        mut_func = random.choice(MUTATORS)
        variant = mut_func(base)
        mutations.append({'dork': variant, 'score': score_dork(variant), 'type': 'variant'})
    
    # Shuffle and trim
    random.shuffle(mutations)
    return mutations[:num_mut]

def main(file_path: str = 'google-dorks.txt', mut_per_base: int = 30):
    dorks = extract_dorks(file_path)
    
    all_mutations = []
    tiered = defaultdict(list)  # By score
    
    for i, base in enumerate(dorks):
        print(f"Mutating {i+1}/{len(dorks)}: {base[:50]}...")
        muts = mutate_dork(base, mut_per_base)
        all_mutations.extend(muts)
        for m in muts:
            tiered[m['score']].append(m['dork'])
    
    # Sort tiers descending
    for s in sorted(tiered.keys(), reverse=True):
        tiered[s].sort()
    
    # Dump JSON (full with metadata)
    with open('mutations-tier1.json', 'w') as f:
        json.dump(all_mutations, f, indent=2)
    
    # Flat list for quick use
    flat = [m['dork'] for m in all_mutations]
    with open('full-flat-list.txt', 'w') as f:
        f.write('\n'.join(flat))
    
    # Tier summary
    print("\nTier Summary:")
    for score in sorted(tiered, reverse=True):
        print(f"Tier {score}: {len(tiered[score])} dorks")
    
    total = len(all_mutations)
    print(f"\nGenerated {total} total mutations (~{total//len(dorks)}x base). Files ready.")

if __name__ == '__main__':
    main()
