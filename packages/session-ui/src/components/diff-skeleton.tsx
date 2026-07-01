 import { For, type JSX } from "solid-js"

export function DiffSkeleton(props: { lines: number }): JSX.Element {
  const count = Math.min(props.lines, 50)
  return (
    <div data-slot="diff-skeleton" aria-busy="true">
      <For each={Array.from({ length: count }, (_, i) => i)}>
        {() => (
          <div data-slot="diff-skeleton-line">
            <div data-slot="diff-skeleton-line-gutter" />
            <div data-slot="diff-skeleton-line-content" />
          </div>
        )}
      </For>
    </div>
  )
}
