package main

import (
    "time"
    "github.com/google/uuid"
)

type Customer struct {
	ID uuid.UUID
	Name string
	CreatedAt time.Time
	UpdatedAt time.Time
}

