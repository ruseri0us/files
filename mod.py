def ran_str_hex(n):
    return ''.join(random.choices('0123456789abcdef', k=n))


# _adbac450-a496-4955-a919-40399ad95218

def random_string():
    return '_' + ran_str_hex(8) + '-' + ran_str_hex(4) + '-' + ran_str_hex(4) + '-' + ran_str_hex(4) + '-' + ran_str_hex(12)

