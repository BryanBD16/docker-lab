import { Component, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { toSignal } from '@angular/core/rxjs-interop';

interface Task {
  id: number;
  title: string;
  description: string | null;
  is_completed: number;   // MySQL BOOLEAN comes back as 0 / 1
  priority: string;
  due_date: string | null;
}

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  private http = inject(HttpClient);
  // Relative URL → goes to localhost:4200/api/tasks → proxied to backend:3000
  protected readonly tasks = toSignal(this.http.get<Task[]>('/api/tasks'), { initialValue: [] });
}