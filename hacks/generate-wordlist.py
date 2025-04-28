import re
import itertools

password_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_ !\"$%&'*+,./:;=?@\\^_`|~{}()[]"
prefix = "prefix_"
suffix = "_suffix"

def gen_password_chars(length):
    """Generate a list of password characters of a given length."""
    return [list(chars) for chars in itertools.product(list(password_chars), repeat=length)]

def generate_wordlist():
    # Split the prefix into characters
    expanded = [list(prefix)]
    
    expanded = [prev + gen
        for length in range(1, 4)
        for gen in gen_password_chars(length)
        for prev in expanded
    ]
    return [''.join(chars) + suffix for chars in expanded]

# Example usage
if __name__ == "__main__":
    #print("Generating wordlist for pattern: " + password_chars)
    #print("Ex " + ('\n'.join(gen_password_chars(2))))
    #print(list(prefix))
    #print(gen_password_chars(2))
    
    wordlist = generate_wordlist()
    print("\n".join(wordlist))
