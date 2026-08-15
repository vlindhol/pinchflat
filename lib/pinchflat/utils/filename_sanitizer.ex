defmodule Pinchflat.Utils.FilenameSanitizer do
  @moduledoc """
  Sanitizes path components for filesystem safety and media server compatibility.

  Applied to values provided by Pinchflat (like `source_custom_name`) before
  they are substituted into yt-dlp output templates as literal text.

  This normalization handles Unicode edge cases (e.g. full-width punctuation,
  curly quotes) that commonly appear in YouTube metadata and can confuse
  media servers like Emby, Jellyfin, Plex, and Infuse.

  Unlike yt-dlp's `--restrict-filenames`, this is intentionally conservative:
  spaces in directory names are preserved (only normalized), so user-friendly
  directories like "Smosh Games" are not mangled into "Smosh_Games".
  """

  # Unicode replacements: full-width → ASCII equivalents
  @unicode_replacements %{
    # Full-width punctuation (common in YouTube titles/channel names)
    # Full-width Colon (U+FF1A)
    "：" => "-",
    # Full-width Comma (U+FF0C)
    "，" => ", ",
    # Full-width Exclamation (U+FF01)
    "！" => "!",
    # Full-width Question Mark (U+FF1F)
    "？" => "?",
    # Full-width Solibdus (U+FF0F)
    "／" => "-",
    # Full-width Reverse Solibdus (U+FF3C)
    "＼" => "-",
    # Full-width Left Parenthesis (U+FF08)
    "（" => "(",
    # Full-width Right Parenthesis (U+FF09)
    "）" => ")",
    # Full-width Left Square Bracket (U+FF3B)
    "［" => "[",
    # Full-width Right Square Bracket (U+FF3D)
    "］" => "]",
    # Full-width Less-Than Sign (U+FF1C)
    "＜" => "<",
    # Full-width Greater-Than Sign (U+FF1E)
    "＞" => ">",

    # Curly quotes → ASCII quotes
    # Left Double Quotation Mark (U+201C)
    "“" => "\"",
    # Right Double Quotation Mark (U+201D)
    "”" => "\"",
    # Double Low-9 Quotation Mark (U+201E)
    "„" => "\"",
    # Right Single Quotation Mark (U+2019)
    "’" => "'",
    # Left Single Quotation Mark (U+2018)
    "‘" => "'",
    # Single Low-9 Quotation Mark (U+201A)
    "‚" => "'",

    # Dashes → hyphen
    # Em Dash (U+2014)
    "—" => "-",
    # En Dash (U+2013)
    "–" => "-",
    # Horizontal Bar (U+2015)
    "―" => "-",

    # Ellipsis → three dots
    # Horizontal Ellipsis (U+2026)
    "…" => "...",

    # Misc
    # Middle Dot (U+00B7)  - common in CJK/ Asian text
    "·" => "-",
    # Bullet (U+2022)
    "•" => "-",
    # White Bullet (U+25E6)
    "◦" => "-",
    # Ideographic Space (U+3000)
    "　" => " ",
    # No-Break Space (U+00A0)
    " " => " ",
    # En Quad (U+2000)
    " " => " ",
    # Em Space (U+2003)
    " " => " ",
    # Thin Space (U+2009)
    " " => " ",
    # Narrow No-Break Space (U+202F)
    " " => " ",
    # Medium Mathematical Space (U+205F)
    " " => " ",
    # Zero Width Space (U+200B)
    "​" => "",
    # Zero Width Non-Joiner (U+200C)
    "‌" => "",
    # Zero Width Joiner (U+200D)
    "‍" => "",
    # Work Joiner (U+2060)
    "⁠" => "",
    # Byte Order Mark (U+FEFF)
    "﻿" => ""
  }

  @doc """
  Sanitizes a single path component (not a full path).

  This is designed for values that Pinchflat substitutes into output templates
  (like `source_custom_name`). It normalizes Unicode but preserves spaces and
  standard ASCII punctuation that media servers expect.

  Double quotes, path separators, colons and other Windows-illegal characters
  are replaced with underscores (mirroring yt-dlp's `--windows-filenames`).

  Returns a binary that is safe to embed as a literal path component.

  Examples:
      iex> FilenameSanitizer.sanitize_path_component("Smosh Games")
      "Smosh Games"

      iex> FilenameSanitizer.sanitize_path_component("Beopardy Takeover： Amanda")
      "Beopardy Takeover- Amanda"
  """
  def sanitize_path_component(value) when is_binary(value) do
    value
    |> normalize_unicode()
    # Replace remaining problems: only keep letters, numbers, and safe punctuation
    |> String.replace(~r/[^\p{L}\p{N}\p{M}\s@+(){}\[\]\-.,&'_$%#~!]/u, "_")
    # Collapse multiple spaces/trim leading/trailing spaces only - preserves single spaces
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    # Remove trailing periods (Windows disallows paths ending in ".")
    |> String.trim_trailing(".")
    |> case do
      "" -> "_"
      other -> other
    end
  end

  @doc """
  Applies full Unicode normalization: replaces full-width punctuation,
  curly quotes, special dashes/spaces, etc. with their ASCII equivalents.

  Preserves existing safe characters. Does not add or remove characters
  outside the replacement map.
  """
  def normalize_unicode(value) when is_binary(value) do
    Enum.reduce(@unicode_replacements, value, fn {from, to}, acc ->
      String.replace(acc, from, to)
    end)
  end
end
