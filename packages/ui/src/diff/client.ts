import { DiffPreparation } from "./client-core"

type DiffSource = { file: string; patch?: string; before?: string; after?: string }

let pool: WorkerPool | undefined

export function prepareDiff(source: DiffSource) {
  if (!pool) pool = new WorkerPool(poolSize())
  return pool.prepare(source)
}

export function prewarm() {
  if (pool) return
  pool = new WorkerPool(poolSize())
}

function poolSize() {
  if (typeof navigator !== "undefined") return Math.min(navigator.hardwareConcurrency ?? 4, 4)
  return 1
}

class WorkerPool {
  private workers: DiffPreparation[]
  private next = 0

  constructor(size: number) {
    this.workers = Array.from({ length: size }, () => this.createWorker())
  }

  prepare(source: DiffSource) {
    const idx = this.next++ % this.workers.length
    return this.workers[idx].prepare(source)
  }

  private createWorker(): DiffPreparation {
    const w = new Worker(new URL("./worker.ts", import.meta.url), { type: "module" })
    const prep = new DiffPreparation(w, () => this.replaceWorker(prep))
    return prep
  }

  private replaceWorker(prep: DiffPreparation) {
    const i = this.workers.indexOf(prep)
    if (i === -1) return
    this.workers[i] = this.createWorker()
  }
}
