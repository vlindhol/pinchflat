defmodule Pinchflat.Utils.FilenameSanitizerTest do
  use ExUnit.Case, async: true

  alias Pinchflat.Utils.FilenameSanitizer

  describe "sanitize_path_component/1" do
    test "preserves spaces and safe ASCII characters" do
      assert FilenameSanitizer.sanitize_path_component("Smosh Games") == "Smosh Games"
    end

    test "preserves common punctuation used in media directories" do
      assert FilenameSanitizer.sanitize_path_component("Then & Now") == "Then & Now"
      assert FilenameSanitizer.sanitize_path_component("SmoshCast (Official)") == "SmoshCast (Official)"
      assert FilenameSanitizer.sanitize_path_component("3Blue1Brown") == "3Blue1Brown"
    end

    test "replaces full-width colons with a hyphen" do
      assert FilenameSanitizer.sanitize_path_component("Werewolf： Chosen Edition") ==
               "Werewolf- Chosen Edition"
    end

    test "normalizes curly quotes" do
      # Double quotes are Windows-illegal so they're replaced with underscores
      # (mirrors yt-dlp's --windows-filenames behaviour)
      assert FilenameSanitizer.sanitize_path_component("He said “hello”") == "He said _hello_"
      # Single quotes are fine everywhere
      assert FilenameSanitizer.sanitize_path_component("It’s fine") == "It's fine"
    end

    test "normalizes dashes to hyphens" do
      assert FilenameSanitizer.sanitize_path_component("a—b") == "a-b"
      assert FilenameSanitizer.sanitize_path_component("a–b") == "a-b"
      assert FilenameSanitizer.sanitize_path_component("a―b") == "a-b"
    end

    test "replaces ellipsis with three dots" do
      assert FilenameSanitizer.sanitize_path_component("one…two") == "one...two"
    end

    test "normalizes und-breaking and unicode spaces to regular spaces" do
      assert FilenameSanitizer.sanitize_path_component("Smosh Games") == "Smosh Games"
      assert FilenameSanitizer.sanitize_path_component("Smosh　Games") == "Smosh Games"
    end

    test "removes zero-width characters" do
      assert FilenameSanitizer.sanitize_path_component("a​b") == "ab"
    end

    test "strips path separators and other unsafe characters" do
      assert FilenameSanitizer.sanitize_path_component("a/b") == "a_b"
      assert FilenameSanitizer.sanitize_path_component("a\\b") == "a_b"
      # ASCII colon is unsafe on Windows/SMB mounts, and --windows-filenames
      # would rewrite it anyway - better to do it deterministically here
      assert FilenameSanitizer.sanitize_path_component("a:b") == "a_b"
    end

    test "collapses repeated whitespace and trims" do
      assert FilenameSanitizer.sanitize_path_component("  weird   spacing  ") == "weird spacing"
    end

    test "removes trailing periods (illegal on Windows)" do
      assert FilenameSanitizer.sanitize_path_component("folder.") == "folder"
      assert FilenameSanitizer.sanitize_path_component("folder...") == "folder"
    end

    test "falls back to an underscore for empty results" do
      assert FilenameSanitizer.sanitize_path_component("") == "_"
      assert FilenameSanitizer.sanitize_path_component("   ") == "_"
    end
  end

  describe "normalize_unicode/1" do
    test "converts full-width punctuation to ASCII" do
      assert FilenameSanitizer.normalize_unicode("A：B，C！D？E") == "A-B, C!D?E"
    end

    test "leaves regular ASCII untouched" do
      assert FilenameSanitizer.normalize_unicode("No changes needed!") == "No changes needed!"
    end
  end
end
