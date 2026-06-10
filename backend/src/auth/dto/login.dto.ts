import { IsString, MinLength } from 'class-validator';

export class LoginDto {
  @IsString()
  username: string; // Can be username or email

  @IsString()
  @MinLength(6)
  password: string;
}

