#!/usr/bin/env python3

from pandocfilters import toJSONFilter, Image, Link

ptpr = None;

def SetPathToProjectRoot(meta):
  global ptpr
  if ptpr is None:
    result = meta.get("pathToProjectRoot")
    if 'MetaInlines' in result['t']:
        assert result['c']['t'] == 'Str'
        ptpr = result['c']['c']
    elif 'MetaString' in result['t']:
        ptpr = result['c']

def prl(key, value, format, meta):
  SetPathToProjectRoot(meta)
  global ptpr
  if key == 'Image' and value[2][0].startswith("/"):
    value[2][0] = ptpr + value[2][0]
    return Image(*value)
  elif key == 'Link' and value[2][0].startswith("/"):
    value[2][0] = ptpr + value[2][0]
    return Link(*value)

if __name__ == "__main__":
  toJSONFilter(prl)
