import argparse
from pathlib import Path

from ytmusicapi import YTMusic

scripts_env_path = Path("C:/Users/ashro/.scripts/.env")

    
yt = YTMusic("C:/Users/ashro/.scripts/.env/headers_auth.json")


def create_playlist(
    title: str, description: str, playlist_txt: Path, privacy: str = "PUBLIC"
) -> None:
    pl_id = yt.create_playlist(title, description, privacy=privacy)

    songs = playlist_txt.expanduser().resolve()
    with songs.open(encoding="utf-8") as f:
        song_lines = [line.strip() for line in f if " - " in line]

    for line in song_lines:
        title, artist = line.split(" - ", 1)
        results = yt.search(f"{title} {artist}", filter="songs")
        if results:
            yt.add_playlist_items(pl_id, [results[0]["videoId"]])
        else:
            print(f"❌ No results found for: {title} by {artist}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("title", help="Playlist title")
    parser.add_argument("description", help="Playlist description")
    parser.add_argument("playlist-file", help="TXT file with list of songs", type=Path)
    parser.add_argument(
        "--privacy",
        help="playlist privacy setting",
        choices=["PUBLIC", "PRIVATE"],
        default="PUBLIC",
    )
    args = parser.parse_args()
    create_playlist(args.title, args.playlist, args.privacy)


if __name__ == "__main__":
    main()
