package popocore

import (
	"os"
	"path/filepath"
	"testing"
)

// The Dart suite writes the configurations it generates into
// build/tunnel_corpus. This parses every one with the real sing-box.
//
// Without this, the Dart tests could only prove the shape they intended, not
// that the core accepts it — and a config the core rejects is a connection that
// silently never happens.
func TestGeneratedConfigsParse(t *testing.T) {
	dir := filepath.Join("..", "..", "build", "tunnel_corpus")

	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Skipf("no corpus at %s; run the Dart tunnel tests first", dir)
	}
	if len(entries) == 0 {
		t.Fatal("corpus directory is empty")
	}

	checked := 0
	for _, entry := range entries {
		if filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		t.Run(entry.Name(), func(t *testing.T) {
			content, err := os.ReadFile(filepath.Join(dir, entry.Name()))
			if err != nil {
				t.Fatalf("read: %v", err)
			}
			if message := CheckConfig(string(content)); message != "" {
				t.Fatalf("sing-box rejected the generated config: %s", message)
			}
		})
		checked++
	}

	if checked == 0 {
		t.Fatal("no .json files in the corpus")
	}
	t.Logf("validated %d generated configurations", checked)
}
